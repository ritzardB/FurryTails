//
//  AddPetView.swift
//  My Pet
//
//  Created by Richard Balabarcon on 06/11/2025.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct AddPetView: View {

    @Environment(\.dismiss) private var dismiss

    var onPetAdded: (() -> Void)?

    // MARK: - Basic Information

    @State private var name = ""
    @State private var species = ""
    @State private var breed = ""
    @State private var age = ""

    // MARK: - Identity

    @State private var sex = ""
    @State private var color = ""
    @State private var distinguishingMarks = ""
    @State private var microchipNumber = ""

    // MARK: - About

    @State private var bio = ""

    // MARK: - Personality

    @State private var character = ""
    @State private var traits = ""
    @State private var characteristics = ""

    // MARK: - Main Photo

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    // MARK: - State

    @State private var isUploading = false
    @State private var shareAsPost = false

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    var body: some View {

        NavigationView {

            ScrollView {

                VStack(spacing: 22) {

                    // MARK: - Pet Image Picker

                    VStack(spacing: 10) {

                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images
                        ) {

                            VStack(spacing: 12) {

                                if let selectedImageData,
                                   let img = UIImage(data: selectedImageData) {

                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: 220, maxHeight: 220)
                                        .cornerRadius(16)
                                        .shadow(radius: 4)

                                } else {

                                    Image(systemName: "photo.on.rectangle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 110, height: 110)
                                        .foregroundColor(FurryTailsTheme.orange)

                                }

                                Text(
                                    selectedImageData == nil
                                    ? "Select Pet Photo"
                                    : "Change Pet Photo"
                                )
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(FurryTailsTheme.orange)
                            }
                        }
                        .buttonStyle(.plain)
                        .onChange(of: selectedItem) { _, newItem in

                            Task {

                                guard let newItem else {
                                    print("⚠️ No photo selected")
                                    return
                                }

                                do {

                                    if let data = try await newItem.loadTransferable(
                                        type: Data.self
                                    ) {

                                        await MainActor.run {
                                            selectedImageData = data
                                        }

                                        print("✅ Pet photo loaded")
                                        print("📦 Image size: \(data.count) bytes")

                                    } else {

                                        print("❌ Could not load image data")
                                    }

                                } catch {

                                    print("❌ Photo loading failed:")
                                    print(error.localizedDescription)
                                }
                            }
                        }
                    }

                    // MARK: - Share to Feed

                    Toggle(
                        "Share to Feed",
                        isOn: $shareAsPost
                    )
                    .padding(.horizontal)

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

                    VStack(alignment: .leading, spacing: 8) {

                        Text("Short Bio")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(FurryTailsTheme.secondaryText)

                        TextEditor(text: $bio)
                            .frame(minHeight: 90)
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

                    // MARK: - Personality

                    sectionHeader(
                        title: "Personality",
                        icon: "heart.text.square"
                    )

                    VStack(alignment: .leading, spacing: 14) {

                        TextField(
                            "Character (e.g. Playful, Calm, Friendly)",
                            text: $character
                        )
                        .textFieldStyle(.roundedBorder)

                        TextField(
                            "Traits (e.g. Loyal, Energetic, Curious)",
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

                    // MARK: - Add Pet Button

                    Button(action: {

                        print("🟢 ADD PET BUTTON PRESSED")

                        savePet()

                    }) {

                        if isUploading {

                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()

                        } else {

                            Label(
                                "Add Pet",
                                systemImage: "pawprint.fill"
                            )
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                    .background(FurryTailsTheme.primaryGradient)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding(.horizontal)
                    .disabled(isUploading)
                    .opacity(isUploading ? 0.7 : 1.0)

                    Spacer(minLength: 30)
                }
                .padding(.top)
                .padding(.bottom, 20)
            }
            .background(FurryTailsTheme.background.ignoresSafeArea())
            .navigationTitle("Add New Pet")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(
        title: String,
        icon: String
    ) -> some View {

        HStack(spacing: 8) {

            Image(systemName: icon)
                .foregroundColor(FurryTailsTheme.orange)

            Text(title)
                .font(.headline)
                .foregroundColor(FurryTailsTheme.primaryText)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    // MARK: - Save Pet

    private func savePet() {

        print("🐾 savePet() STARTED")

        // --------------------------------------------------
        // 1. Check authenticated Firebase user
        // --------------------------------------------------

        guard let uid = Auth.auth().currentUser?.uid else {

            print("❌ No authenticated Firebase user")
            return
        }

        print("✅ Firebase User UID: \(uid)")

        // --------------------------------------------------
        // 2. Check selected image
        // --------------------------------------------------

        guard let imageData = selectedImageData else {

            print("❌ No pet image selected")
            return
        }

        print("✅ Image data available: \(imageData.count) bytes")

        // --------------------------------------------------
        // 3. Validate pet name
        // --------------------------------------------------

        let trimmedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedName.isEmpty else {

            print("❌ Pet name is empty")
            return
        }

        // --------------------------------------------------
        // 4. Prepare values
        // --------------------------------------------------

        let trimmedSpecies = species.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedBreed = breed.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedSex = sex.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedColor = color.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedMarks = distinguishingMarks.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedMicrochip = microchipNumber.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedBio = bio.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedCharacter = character.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedTraits = traits.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedCharacteristics = characteristics.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        // --------------------------------------------------
        // 5. Begin upload
        // --------------------------------------------------

        isUploading = true

        let petId = UUID().uuidString

        let imageRef = storage
            .reference()
            .child("pet_images/\(petId).jpg")

        print("🐾 Pet ID: \(petId)")
        print("📁 Storage path: pet_images/\(petId).jpg")

        Task {

            do {

                // --------------------------------------------------
                // 6. Upload main pet image
                // --------------------------------------------------

                print("📤 Uploading pet image...")

                _ = try await imageRef.putDataAsync(
                    imageData,
                    metadata: nil
                )

                print("✅ Pet image uploaded successfully")

                // --------------------------------------------------
                // 7. Get download URL
                // --------------------------------------------------

                print("🔗 Getting pet image download URL...")

                let url = try await imageRef.downloadURL()

                print("✅ Download URL obtained")
                print("🔗 \(url.absoluteString)")

                // --------------------------------------------------
                // 8. Prepare Firestore pet document
                // --------------------------------------------------

                let petData: [String: Any] = [

                    "id": petId,

                    "name": trimmedName,

                    "species": trimmedSpecies,

                    "breed": trimmedBreed,

                    "age": Int(age) ?? 0,

                    "sex": trimmedSex,

                    "color": trimmedColor,

                    "distinguishingMarks": trimmedMarks,

                    "microchipNumber": trimmedMicrochip,

                    "bio": trimmedBio,

                    "ownerId": uid,

                    "character": trimmedCharacter,

                    "traits": trimmedTraits,

                    "characteristics": trimmedCharacteristics,

                    // Keep this as a String for now
                    // for compatibility with existing Firestore data.
                    "petImageURL": url.absoluteString,

                    "petGalleryURLs": "",

                    "createdAt": Timestamp(),

                    "updatedAt": Timestamp()
                ]

                print("📄 Pet document prepared")
                print("📄 Collection: pets")
                print("📄 Document ID: \(petId)")
                print("👤 ownerId: \(uid)")
                print("🐾 Sex: \(trimmedSex)")
                print("🎨 Color: \(trimmedColor)")
                print("🔖 Microchip: \(trimmedMicrochip.isEmpty ? "Not specified" : trimmedMicrochip)")

                // --------------------------------------------------
                // 9. Write to Firestore
                // --------------------------------------------------

                print("📡 Saving pet to Firestore...")

                let petRef = db
                    .collection("pets")
                    .document(petId)

                try await withCheckedThrowingContinuation {
                    (
                        continuation: CheckedContinuation<Void, Error>
                    ) in

                    petRef.setData(petData) { error in

                        if let error {

                            continuation.resume(
                                throwing: error
                            )

                        } else {

                            continuation.resume(
                                returning: ()
                            )
                        }
                    }
                }

                print("✅ PET SAVED TO FIRESTORE")
                print("🐾 /pets/\(petId)")

                // --------------------------------------------------
                // 10. Optional: Share pet as post
                // --------------------------------------------------

                if shareAsPost {

                    let postId = UUID().uuidString

                    let postData: [String: Any] = [

                        "id": postId,

                        "caption": "Meet my pet \(trimmedName)! 🐾",

                        "imageURL": url.absoluteString,

                        "ownerId": uid,

                        "likes": 0,

                        "reposts": 0,

                        "comments": 0,

                        "shares": 0,

                        "createdAt": Timestamp(),

                        "mediaType": "image"
                    ]

                    print("📡 Sharing pet as post...")
                    print("📄 Post ID: \(postId)")

                    let postRef = db
                        .collection("posts")
                        .document(postId)

                    try await withCheckedThrowingContinuation {
                        (
                            continuation: CheckedContinuation<Void, Error>
                        ) in

                        postRef.setData(postData) { error in

                            if let error {

                                continuation.resume(
                                    throwing: error
                                )

                            } else {

                                continuation.resume(
                                    returning: ()
                                )
                            }
                        }
                    }

                    print("✅ Pet shared to feed")
                }

                // --------------------------------------------------
                // 11. Finished
                // --------------------------------------------------

                print("🎉 PET CREATION COMPLETE")

                await MainActor.run {

                    isUploading = false

                    onPetAdded?()

                    dismiss()
                }

            } catch {

                print("❌ PET CREATION FAILED")
                print("❌ Error: \(error)")
                print("❌ Description: \(error.localizedDescription)")

                await MainActor.run {

                    isUploading = false
                }
            }
        }
    }
}
