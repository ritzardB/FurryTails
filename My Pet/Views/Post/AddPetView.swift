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

    @State private var name = ""
    @State private var species = ""
    @State private var breed = ""
    @State private var age = ""
    @State private var bio = ""

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    @State private var isUploading = false
    @State private var shareAsPost = false

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    var body: some View {

        NavigationView {

            ScrollView {

                VStack(spacing: 20) {

                    // MARK: - Pet Image Picker

                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images
                    ) {

                        VStack {

                            if let selectedImageData,
                               let img = UIImage(data: selectedImageData) {

                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 200)
                                    .cornerRadius(12)

                            } else {

                                Image(systemName: "photo.on.rectangle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120)
                                    .foregroundColor(.gray)
                            }

                            Text("Select Pet Photo")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
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

                    // MARK: - Share to Feed

                    Toggle(
                        "Share to Feed",
                        isOn: $shareAsPost
                    )
                    .padding(.horizontal)

                    // MARK: - Pet Information

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

                        TextField(
                            "Short Bio",
                            text: $bio
                        )
                    }
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                    // MARK: - Add Pet Button

                    Button(action: {
                        print("🟢 ADD PET BUTTON PRESSED")
                        savePet()
                    }) {

                        if isUploading {

                            ProgressView()
                                .padding()

                        } else {

                            Text("Add Pet")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
                    .disabled(isUploading)
                }
                .padding()
                .navigationTitle("Add New Pet")
            }
        }
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
        // 4. Begin upload
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
                // 5. Upload image to Firebase Storage
                // --------------------------------------------------

                print("📤 Uploading pet image...")

                _ = try await imageRef.putDataAsync(
                    imageData,
                    metadata: nil
                )

                print("✅ Pet image uploaded successfully")

                // --------------------------------------------------
                // 6. Get download URL
                // --------------------------------------------------

                print("🔗 Getting pet image download URL...")

                let url = try await imageRef.downloadURL()

                print("✅ Download URL obtained")
                print("🔗 \(url.absoluteString)")

                // --------------------------------------------------
                // 7. Prepare Firestore pet document
                // --------------------------------------------------

                let petData: [String: Any] = [

                    "id": petId,

                    "name": trimmedName,

                    "species": species.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),

                    "breed": breed.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),

                    "age": Int(age) ?? 0,

                    "bio": bio.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),

                    "ownerId": uid,

                    "character": "",

                    "traits": "",

                    "petImageURL": url.absoluteString,

                    "petGalleryURLs": "",

                    "createdAt": Timestamp(),

                    "updatedAt": Timestamp()
                ]

                print("📄 Pet document prepared")
                print("📄 Collection: pets")
                print("📄 Document ID: \(petId)")
                print("👤 ownerId: \(uid)")

                // --------------------------------------------------
                // 8. Write to Firestore /pets/{petId}
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
                // 9. Optional: Share pet as post
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
                // 10. Finished
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
