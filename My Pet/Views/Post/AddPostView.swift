//
//  AddPostView.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

struct AddPostView: View {
    @State private var caption = ""

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []

    @State private var isUploading = false
    
    @Environment(\.dismiss) private var dismiss

    let initialImageURL: URL?
    let dismissAfterPosting: Bool

    @State private var isLoadingInitialImage = false
    
    init(
        initialImageURL: URL? = nil,
        dismissAfterPosting: Bool = false
    ) {
        self.initialImageURL = initialImageURL
        self.dismissAfterPosting = dismissAfterPosting
    }

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Photo Picker

                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        VStack(spacing: 10) {

                            if selectedImages.isEmpty {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 90, height: 90)
                                    .foregroundColor(.gray)

                                Text("Select Photos")
                                    .font(.headline)
                                    .foregroundColor(.blue)

                                Text("Up to 10 photos")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                            } else {
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ],
                                    spacing: 8
                                ) {
                                    ForEach(
                                        Array(selectedImages.enumerated()),
                                        id: \.offset
                                    ) { index, image in

                                        ZStack(alignment: .topTrailing) {

                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(
                                                    width: 100,
                                                    height: 100
                                                )
                                                .clipped()
                                                .cornerRadius(8)

                                            Button {
                                                removeImage(at: index)
                                            } label: {
                                                Image(
                                                    systemName: "xmark.circle.fill"
                                                )
                                                .font(.title3)
                                                .foregroundColor(.white)
                                                .background(
                                                    Circle()
                                                        .fill(Color.black.opacity(0.5))
                                                )
                                            }
                                            .padding(4)
                                        }
                                    }
                                }

                                Text(
                                    "\(selectedImages.count) / 10 photos selected"
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .onChange(of: selectedItems) { _, newItems in
                        Task {
                            await loadSelectedImages(newItems)
                        }
                    }

                    // MARK: - Caption

                    TextField(
                        "Write a caption ...",
                        text: $caption
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                    // MARK: - Post Button

                    Button {
                        uploadPost()
                    } label: {
                        if isUploading {
                            ProgressView()
                                .padding()
                        } else {
                            Text("Post")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    selectedImages.isEmpty
                                    ? Color.gray
                                    : Color.blue
                                )
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                    .disabled(
                        isUploading ||
                        selectedImages.isEmpty
                    )
                }
                .padding()
            }
            .navigationTitle("Create Post")
        }
        .onAppear {
            guard
                let imageURL = initialImageURL,
                selectedImages.isEmpty,
                !isLoadingInitialImage
            else {
                return
            }

            isLoadingInitialImage = true

            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(
                        from: imageURL
                    )

                    guard let image = UIImage(data: data) else {
                        throw NSError(
                            domain: "AddPostView",
                            code: 1,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "Unable to load the selected gallery photo."
                            ]
                        )
                    }

                    await MainActor.run {
                        selectedImages = [image]
                        isLoadingInitialImage = false
                    }

                    print("✅ Gallery photo loaded into post composer")

                } catch {
                    await MainActor.run {
                        isLoadingInitialImage = false
                    }

                    print(
                        "❌ Failed to load gallery photo: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    // MARK: - Load Selected Images

    private func loadSelectedImages(
        _ items: [PhotosPickerItem]
    ) async {

        var images: [UIImage] = []

        for item in items.prefix(10) {
            do {
                if let data = try await item.loadTransferable(
                    type: Data.self
                ),
                   let image = UIImage(data: data) {

                    images.append(image)
                }
            } catch {
                print(
                    "❌ Failed to load selected image: \(error)"
                )
            }
        }

        await MainActor.run {
            selectedImages = images
        }

        print(
            "📸 Loaded \(images.count) selected images"
        )
    }

    // MARK: - Remove Image

    private func removeImage(at index: Int) {

        guard selectedImages.indices.contains(index) else {
            return
        }

        selectedImages.remove(at: index)

        if selectedItems.indices.contains(index) {
            selectedItems.remove(at: index)
        }

        print(
            "🗑️ Removed image at index \(index)"
        )
    }

    // MARK: - Upload Post

    private func uploadPost() {

        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated Firebase user")
            return
        }

        guard !selectedImages.isEmpty else {
            print("❌ No photos selected")
            return
        }

        isUploading = true

        let postId = UUID().uuidString

        Task {

            do {

                var imageURLs: [String] = []

                // MARK: Upload Photos

                for (index, image) in selectedImages.enumerated() {

                    guard let imageData = image.jpegData(
                        compressionQuality: 0.85
                    ) else {
                        print(
                            "❌ Could not convert image \(index + 1)"
                        )
                        continue
                    }

                    let imageNumber = String(
                        format: "%02d",
                        index + 1
                    )

                    let storagePath =
                        "posts_media/\(postId)/\(imageNumber).jpg"

                    let storageRef =
                        storage.reference()
                            .child(storagePath)

                    print(
                        "📤 Uploading photo \(index + 1)/\(selectedImages.count)"
                    )

                    print(
                        "📁 Storage path: \(storagePath)"
                    )

                    _ = try await storageRef.putDataAsync(
                        imageData
                    )

                    let downloadURL =
                        try await storageRef.downloadURL()

                    imageURLs.append(
                        downloadURL.absoluteString
                    )

                    print(
                        "✅ Photo \(index + 1) uploaded"
                    )
                }

                guard !imageURLs.isEmpty else {
                    throw NSError(
                        domain: "AddPostView",
                        code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "No images were uploaded."
                        ]
                    )
                }

                // MARK: Firestore Post

                let postData: [String: Any] = [
                    "id": postId,

                    // Keep first image for backward compatibility
                    "imageURL": imageURLs[0],

                    // New multi-photo field
                    "imageURLs": imageURLs,

                    "mediaType": "image",

                    "caption": caption
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ),

                    "ownerId": userId,

                    "likes": 0,
                    "reposts": 0,
                    "comments": 0,

                    "createdAt": Timestamp()
                ]

                print(
                    "📡 Saving post to Firestore..."
                )

                print(
                    "📄 Post ID: \(postId)"
                )

                print(
                    "📸 Number of photos: \(imageURLs.count)"
                )

                let postRef =
                    db.collection("posts")
                        .document(postId)

                try await withCheckedThrowingContinuation {
                    (
                        continuation:
                            CheckedContinuation<Void, Error>
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

                print(
                    "✅ POST SAVED TO FIRESTORE"
                )

                print(
                    "🎉 POST CREATION COMPLETE"
                )

                await MainActor.run {

                    caption = ""

                    selectedItems = []
                    selectedImages = []

                    isUploading = false

                    NotificationCenter.default.post(
                        name: .postCreated,
                        object: nil
                    )
                    
                    if dismissAfterPosting {
                        dismiss()
                    }
                }

            } catch {

                print(
                    "❌ POST CREATION FAILED"
                )

                print(
                    "❌ Error: \(error)"
                )

                print(
                    "❌ Description: \(error.localizedDescription)"
                )

                await MainActor.run {
                    isUploading = false
                }
            }
        }
    }
}
