//
//  PostUploadViewModel.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//
import SwiftUI
import FirebaseStorage
import Combine
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseAuth

@MainActor
final class PostUploadViewModel: ObservableObject {
    @Published var caption: String = ""
    @Published var selectedMediaURL: URL?
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var uploadSuccess = false
    @Published var errorMessage: String?

    private let storage = Storage.storage()
    private let db = Firestore.firestore()

    func uploadPost(dismiss: @escaping () -> Void) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            return
        }

        guard let imageURL = selectedMediaURL else {
            errorMessage = "No media selected."
            return
        }

        isUploading = true
        uploadProgress = 0.0

        do {
            let fileName = UUID().uuidString
            let fileExtension = imageURL.pathExtension.lowercased()
            let isImage = ["jpg", "jpeg", "png"].contains(fileExtension)
            let mediaType = isImage ? "image" : "video"
            let folder = isImage ? "Post_images" : "Post_videos"
            let storageRef = storage.reference().child("\(folder)/\(fileName).\(fileExtension)")

            var uploadTask: StorageUploadTask
            if isImage, let data = try? Data(contentsOf: imageURL) {
                uploadTask = storageRef.putData(data, metadata: nil)
            } else {
                uploadTask = storageRef.putFile(from: imageURL, metadata: nil)
            }

            // Observe upload progress
            uploadTask.observe(.progress) { snapshot in
                if let progress = snapshot.progress {
                    DispatchQueue.main.async {
                        self.uploadProgress = progress.fractionCompleted
                    }
                }
            }

            // Wait for upload completion
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StorageMetadata, Error>) in
                uploadTask.observe(.success) { snapshot in
                    continuation.resume(returning: snapshot.metadata!)
                }
                uploadTask.observe(.failure) { snapshot in
                    continuation.resume(throwing: snapshot.error ?? NSError(domain: "UploadError", code: -1))
                }
            }

            let downloadURL = try await storageRef.downloadURL()

            // Prepare Firestore data
            let postData: [String: Any] = [
                "caption": caption,
                "imageURL": downloadURL.absoluteString,
                "ownerId": uid,
                "mediaType": mediaType,
                "createdAt": FieldValue.serverTimestamp(),
                "likes": 0,
                "reposts": 0,
                "comments": 0
            ]

            // Save in global posts collection
            _ = try await db.collection("posts").addDocument(data: postData)
//            // Also save under the user’s personal posts subcollection
//            try await db.collection("users").document(uid)
//                .collection("posts")
//                .document(postRef.documentID)
//                .setData(postData)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.uploadSuccess = true
                self.isUploading = false
                self.caption = ""
                self.selectedMediaURL = nil
                dismiss()
            }

        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "❌ Upload or Firestore error: \(error.localizedDescription)"
                self.isUploading = false
            }
        }
    }
}

