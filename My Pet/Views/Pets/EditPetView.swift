//
//  EditPetView.swift
//  My Pet
//
//  Created by Richard Balabarcon on 08/10/2026.
//

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

    // MARK: - Photo

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

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

                    // MARK: Current Photo

                    currentPhotoSection

                    // MARK: Basic Information

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

                    // MARK: Pet Identity

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

                    // MARK: About

                    sectionHeader(
                        title: "About",
                        icon: "text.alignleft"
                    )

                    VStack(alignment: .leading, spacing: 8) {

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
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        Color.gray.opacity(0.25),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .padding(.horizontal)

                    // MARK: Personality

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

                    // MARK: Error

                    if let errorMessage {

                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // MARK: Save

                    Button {
                        saveChanges()
                    } label: {

                        if isSaving {

                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()

                        } else {

                            Label(
                                "Save Changes",
                                systemImage: "checkmark.circle.fill"
                            )
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
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
               let image = UIImage(data: selectedImageData) {

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 170, height: 170)
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
                            .frame(width: 170, height: 170)

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
            .onChange(of: selectedItem) { _, newItem in

                Task {

                    guard let newItem else {
                        return
                    }

                    do {

                        if let data = try await newItem.loadTransferable(
                            type: Data.self
                        ) {

                            await MainActor.run {
                                selectedImageData = data
                            }

                            print("✅ New pet image selected")
                            print(
                                "📦 Image size: \(data.count) bytes"
                            )
                        }

                    } catch {

                        print(
                            "❌ Failed to load new pet image:"
                        )
                        print(error.localizedDescription)
                    }
                }
            }
        }
        .padding(.top, 10)
    }

    // MARK: - Default Image

    private var defaultPetImage: some View {

        Circle()
            .fill(
                FurryTailsTheme.orangeSoft.opacity(0.55)
            )
            .frame(width: 170, height: 170)
            .overlay {

                Image(systemName: "pawprint.fill")
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

        print("✏️ saveChanges() STARTED")

        guard let uid = Auth.auth().currentUser?.uid else {

            print("❌ No authenticated Firebase user")

            errorMessage = "You must be signed in to edit a pet."

            return
        }

        guard let petId = pet.id,
              !petId.isEmpty else {

            print("❌ Pet has no document ID")

            errorMessage = "Unable to identify this pet."

            return
        }

        let trimmedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedName.isEmpty else {

            errorMessage = "Pet name cannot be empty."

            return
        }

        isSaving = true
        errorMessage = nil

        Task {

            do {

                var updatedImageURL = pet.petImageURL

                // MARK: Upload New Image If Selected

                if let selectedImageData {

                    let imageRef = storage
                        .reference()
                        .child(
                            "pet_images/\(petId).jpg"
                        )

                    print("📤 Uploading updated pet image...")

                    _ = try await imageRef.putDataAsync(
                        selectedImageData,
                        metadata: nil
                    )

                    let newURL = try await imageRef.downloadURL()

                    updatedImageURL = newURL.absoluteString

                    print(
                        "✅ Updated image URL obtained"
                    )
                }

                // MARK: Firestore Update

                let updates: [String: Any] = [

                    "name": trimmedName,

                    "species": species.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),

                    "breed": breed.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),

                    "age": Int(age) ?? 0,

                    "sex": sex.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),

                    "color": color.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),

                    "distinguishingMarks":
                        distinguishingMarks.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ),

                    "microchipNumber":
                        microchipNumber.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ),

                    "bio": bio.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),

                    "character": character.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),

                    "traits": traits.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),

                    "characteristics":
                        characteristics.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ),

                    "petImageURL": updatedImageURL,

                    "updatedAt": Timestamp()
                ]

                print("📡 Updating Firestore pet...")
                print("🐾 Pet ID: \(petId)")
                print("👤 Current user: \(uid)")

                try await db
                    .collection("pets")
                    .document(petId)
                    .updateData(updates)

                print("✅ PET UPDATED SUCCESSFULLY")

                await MainActor.run {

                    isSaving = false

                    onPetUpdated?()

                    dismiss()
                }

            } catch {

                print("❌ PET UPDATE FAILED")
                print("❌ Error: \(error)")
                print(
                    "❌ Description: \(error.localizedDescription)"
                )

                await MainActor.run {

                    isSaving = false

                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
