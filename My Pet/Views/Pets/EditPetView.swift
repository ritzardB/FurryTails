//
//  EditPetView.swift
//  My Pet
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct EditPetView: View {

    @Environment(\.dismiss) private var dismiss

    let pet: Pet
    var onPetUpdated: (() -> Void)?

    // MARK: - Basic Information

    @State private var name: String
    @State private var species: String
    @State private var breed: String
    @State private var age: String

    // MARK: - Identity

    @State private var sex: String
    @State private var color: String
    @State private var distinguishingMarks: String
    @State private var microchipNumber: String

    // MARK: - About

    @State private var bio: String

    // MARK: - Personality

    @State private var character: String
    @State private var traits: String
    @State private var characteristics: String

    // MARK: - Main Photo

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    // MARK: - Gallery

    @State private var selectedGalleryItems: [PhotosPickerItem] = []
    @State private var selectedGalleryImages: [UIImage] = []

    // MARK: - State

    @State private var isSaving = false
    @State private var errorMessage: String?

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    // MARK: - Initializer

    init(
        pet: Pet,
        onPetUpdated: (() -> Void)? = nil
    ) {
        self.pet = pet
        self.onPetUpdated = onPetUpdated

        _name = State(initialValue: pet.name)
        _species = State(initialValue: pet.species)
        _breed = State(initialValue: pet.breed ?? "")
        _age = State(initialValue: pet.age.map(String.init) ?? "")

        _sex = State(initialValue: pet.sex ?? "")
        _color = State(initialValue: pet.color ?? "")
        _distinguishingMarks = State(
            initialValue: pet.distinguishingMarks ?? ""
        )
        _microchipNumber = State(
            initialValue: pet.microchipNumber ?? ""
        )

        _bio = State(initialValue: pet.bio ?? "")

        _character = State(initialValue: pet.character ?? "")
        _traits = State(initialValue: pet.traits ?? "")
        _characteristics = State(
            initialValue: pet.characteristics ?? ""
        )
    }

    // MARK: - Body

    var body: some View {

        NavigationView {

            ScrollView {

                VStack(spacing: 22) {

                    // MARK: - Current Photo

                    currentPhotoSection

                    // MARK: - Basic Information

                    sectionHeader(
                        title: "Basic Information",
                        icon: "pawprint.fill"
                    )

                    Group {

                        TextField(
                            "Pet Name",
                            text: $name
                        )

                        TextField(
                            "Species",
                            text: $species
                        )

                        TextField(
                            "Breed",
                            text: $breed
                        )

                        TextField(
                            "Age",
                            text: $age
                        )
                        .keyboardType(.numberPad)
                    }
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                    // MARK: - Pet Identity

                    sectionHeader(
                        title: "Pet Identity",
                        icon: "person.text.rectangle"
                    )

                    Group {

                        TextField(
                            "Sex (e.g. Male, Female)",
                            text: $sex
                        )

                        TextField(
                            "Color",
                            text: $color
                        )

                        TextField(
                            "Distinguishing Marks",
                            text: $distinguishingMarks
                        )

                        TextField(
                            "Microchip Number",
                            text: $microchipNumber
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    }
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                    // MARK: - About

                    sectionHeader(
                        title: "About",
                        icon: "text.alignleft"
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Text("Short Bio")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(
                                FurryTailsTheme.secondaryText
                            )

                        TextEditor(text: $bio)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 10
                                )
                                .stroke(
                                    Color.gray.opacity(0.25),
                                    lineWidth: 1
                                )
                            )
                    }
                    .padding(.horizontal)

                    // MARK: - Personality

                    sectionHeader(
                        title: "Personality",
                        icon: "heart.text.square"
                    )

                    VStack(spacing: 14) {

                        TextField(
                            "Character",
                            text: $character
                        )
                        .textFieldStyle(.roundedBorder)

                        TextField(
                            "Traits",
                            text: $traits
                        )
                        .textFieldStyle(.roundedBorder)

                        TextField(
                            "Characteristics",
                            text: $characteristics
                        )
                        .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)

                    // MARK: - Photo Gallery

                    sectionHeader(
                        title: "Photo Gallery",
                        icon: "photo.on.rectangle.angled"
                    )

                    galleryPickerSection

                    // MARK: - Error

                    if let errorMessage {

                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // MARK: - Save

                    Button {

                        saveChanges()

                    } label: {

                        if isSaving {

                            ProgressView()
                                .tint(.white)
                                .frame(
                                    maxWidth: .infinity
                                )
                                .padding()

                        } else {

                            Label(
                                "Save Changes",
                                systemImage:
                                    "checkmark.circle.fill"
                            )
                            .fontWeight(.bold)
                            .frame(
                                maxWidth: .infinity
                            )
                            .padding()
                        }
                    }
                    .background(
                        FurryTailsTheme.primaryGradient
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding(.horizontal)
                    .disabled(isSaving)

                    Spacer(minLength: 30)
                }
                .padding(.top)
                .padding(.bottom, 20)
            }
            .background(
                FurryTailsTheme.background
                    .ignoresSafeArea()
            )
            .navigationTitle("Edit Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .navigationBarLeading
                ) {

                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    // MARK: - Current Photo

    private var currentPhotoSection: some View {

        VStack(spacing: 12) {

            if let selectedImageData,
               let image = UIImage(
                   data: selectedImageData
               ) {

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: 170,
                        height: 170
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                FurryTailsTheme.orange,
                                lineWidth: 4
                            )
                    )

            } else if let url = URL(
                string: pet.petImageURL
            ),
                      !pet.petImageURL.isEmpty {

                AsyncImage(url: url) { phase in

                    switch phase {

                    case .empty:

                        ProgressView()
                            .frame(
                                width: 170,
                                height: 170
                            )

                    case .success(let image):

                        image
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: 170,
                                height: 170
                            )
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        FurryTailsTheme.orange,
                                        lineWidth: 4
                                    )
                            )

                    case .failure:

                        defaultPetImage

                    @unknown default:

                        defaultPetImage
                    }
                }

            } else {

                defaultPetImage
            }

            PhotosPicker(
                selection: $selectedItem,
                matching: .images
            ) {

                Label(
                    "Change Photo",
                    systemImage: "camera.fill"
                )
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(
                    FurryTailsTheme.orange
                )
            }
            .onChange(
                of: selectedItem
            ) { _, newItem in

                Task {

                    guard let newItem else {
                        return
                    }

                    do {

                        if let data =
                            try await newItem.loadTransferable(
                                type: Data.self
                            ) {

                            await MainActor.run {

                                selectedImageData = data
                            }

                            print(
                                "✅ New pet image selected"
                            )

                            print(
                                "📦 Image size: \(data.count) bytes"
                            )
                        }

                    } catch {

                        print(
                            "❌ Failed to load new pet image:"
                        )

                        print(
                            error.localizedDescription
                        )
                    }
                }
            }
        }
        .padding(.top, 10)
    }

    // MARK: - Gallery Picker

    private var galleryPickerSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            PhotosPicker(
                selection: $selectedGalleryItems,
                maxSelectionCount: 10,
                matching: .images
            ) {

                HStack(spacing: 10) {

                    Image(
                        systemName: "plus.circle.fill"
                    )
                    .font(.title3)

                    Text("Add Gallery Photos")
                        .fontWeight(.semibold)

                    Spacer()

                    Image(
                        systemName: "photo.stack.fill"
                    )
                }
                .foregroundColor(
                    FurryTailsTheme.orange
                )
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    FurryTailsTheme.orangeSoft
                        .opacity(0.25)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                )
            }

            if !selectedGalleryImages.isEmpty {

                ScrollView(
                    .horizontal,
                    showsIndicators: false
                ) {

                    HStack(spacing: 12) {

                        ForEach(
                            Array(
                                selectedGalleryImages.enumerated()
                            ),
                            id: \.offset
                        ) { index, image in

                            ZStack(
                                alignment: .topTrailing
                            ) {

                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(
                                        width: 120,
                                        height: 120
                                    )
                                    .clipShape(
                                        RoundedRectangle(
                                            cornerRadius: 12
                                        )
                                    )

                                Button {

                                    removeGalleryPhoto(
                                        at: index
                                    )

                                } label: {

                                    Image(
                                        systemName:
                                            "xmark.circle.fill"
                                    )
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(
                                                Color.black
                                                    .opacity(0.55)
                                            )
                                    )
                                }
                                .padding(6)
                            }
                        }
                    }
                }
            }

            Text(
                "You can select up to 10 photos."
            )
            .font(.caption)
            .foregroundColor(
                FurryTailsTheme.secondaryText
            )
        }
        .padding(.horizontal)
        .onChange(
            of: selectedGalleryItems
        ) { _, newItems in

            loadGalleryImages(
                from: newItems
            )
        }
    }

    // MARK: - Load Gallery Images

    private func loadGalleryImages(
        from items: [PhotosPickerItem]
    ) {

        Task {

            var images: [UIImage] = []

            for item in items {

                do {

                    if let data =
                        try await item.loadTransferable(
                            type: Data.self
                        ),
                       let image = UIImage(data: data) {

                        images.append(image)

                        print(
                            "📸 Gallery photo loaded"
                        )

                        print(
                            "📦 Image size: \(data.count) bytes"
                        )
                    }

                } catch {

                    print(
                        "❌ Failed to load gallery photo:"
                    )

                    print(
                        error.localizedDescription
                    )
                }
            }

            await MainActor.run {

                selectedGalleryImages = images
            }

            print(
                "📸 Selected gallery photos: \(images.count)"
            )
        }
    }

    // MARK: - Remove Gallery Photo

    private func removeGalleryPhoto(
        at index: Int
    ) {

        guard selectedGalleryImages.indices.contains(
            index
        ) else {
            return
        }

        selectedGalleryImages.remove(
            at: index
        )

        if selectedGalleryItems.indices.contains(
            index
        ) {

            selectedGalleryItems.remove(
                at: index
            )
        }

        print(
            "🗑️ Removed gallery photo at index \(index)"
        )
    }

    // MARK: - Default Image

    private var defaultPetImage: some View {

        Circle()
            .fill(
                FurryTailsTheme.orangeSoft
                    .opacity(0.55)
            )
            .frame(
                width: 170,
                height: 170
            )
            .overlay {

                Image(
                    systemName: "pawprint.fill"
                )
                .font(.system(size: 55))
                .foregroundColor(
                    FurryTailsTheme.orange
                )
            }
            .overlay(
                Circle()
                    .stroke(
                        FurryTailsTheme.orange,
                        lineWidth: 4
                    )
            )
    }

    // MARK: - Section Header

    private func sectionHeader(
        title: String,
        icon: String
    ) -> some View {

        HStack(spacing: 8) {

            Image(systemName: icon)
                .foregroundColor(
                    FurryTailsTheme.orange
                )

            Text(title)
                .font(.headline)
                .foregroundColor(
                    FurryTailsTheme.primaryText
                )

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    // MARK: - Save Changes

    private func saveChanges() {
        guard let petId = pet.id else {
            errorMessage = "Pet ID is missing."
            return
        }

        guard Auth.auth().currentUser != nil else {
            errorMessage = "You must be signed in."
            return
        }

        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Pet name is required."
            return
        }

        isSaving = true
        errorMessage = nil

        Task {
            do {
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedSpecies = species.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedBreed = breed.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedSex = sex.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedColor = color.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedMarks = distinguishingMarks.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedMicrochip = microchipNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedCharacter = character.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedTraits = traits.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedCharacteristics = characteristics.trimmingCharacters(in: .whitespacesAndNewlines)

                // MARK: - Main Pet Gallery

                var updatedImageURL = pet.petImageURL

                if let imageData = selectedImageData {

                    let imageRef = storage
                        .reference()
                        .child("pet_images/\(petId).jpg")

                    _ = try await imageRef.putDataAsync(imageData)

                    let downloadURL = try await imageRef.downloadURL()

                    updatedImageURL = downloadURL.absoluteString

                    print("🐾 Main pet image uploaded:")
                    print(downloadURL.absoluteString)
                }
                
                // MARK: - Pet Gallery

                // Start with the existing gallery URLs.
                var galleryURLs = pet.petGalleryURLs

                // Upload newly selected gallery images.
                for image in selectedGalleryImages {

                    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                        continue
                    }

                    let fileName = "\(UUID().uuidString).jpg"

                    let galleryRef = Storage.storage()
                        .reference()
                        .child("pet_images/\(petId)/gallery/\(fileName)")

                    _ = try await galleryRef.putDataAsync(imageData)

                    let downloadURL = try await galleryRef.downloadURL()

                    galleryURLs.append(downloadURL.absoluteString)

                    print("📸 Gallery image uploaded:")
                    print(downloadURL.absoluteString)
                }

                // MARK: - Firestore Update

                let updates: [String: Any] = [
                    "name": trimmedName,
                    "species": trimmedSpecies,
                    "breed": trimmedBreed,
                    "age": Int(age) ?? 0,
                    "sex": trimmedSex,
                    "color": trimmedColor,
                    "distinguishingMarks": trimmedMarks,
                    "microchipNumber": trimmedMicrochip,
                    "bio": trimmedBio,
                    "character": trimmedCharacter,
                    "traits": trimmedTraits,
                    "characteristics": trimmedCharacteristics,
                    "petImageURL": updatedImageURL,
                    "petGalleryURLs": galleryURLs,
                    "updatedAt": Timestamp()
                ]

                try await db
                    .collection("pets")
                    .document(petId)
                    .updateData(updates)

                print("✅ Pet updated successfully")
                print("📸 Gallery count: \(galleryURLs.count)")

                await MainActor.run {
                    isSaving = false
                    onPetUpdated?()
                    dismiss()
                }

            } catch {
                print("❌ Failed to save pet:")
                print(error.localizedDescription)

                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
