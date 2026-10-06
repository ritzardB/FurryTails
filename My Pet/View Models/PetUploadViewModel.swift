//
//  PetUploadViewModel.swift
//  My Pet
//
//  Created by Richard Balabarcon on 31/10/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestoreCombineSwift
import Combine
import FirebaseFirestore
import FirebaseStorage

@MainActor
class PetUploadViewModel: ObservableObject {
    @Published var isUploading = false

    func addPet(name: String, species: String, breed: String?, age: Int?, bio: String?, imageData: Data?) async throws {
        guard let imageData else { throw NSError(domain: "NoImage", code: 0) }
        guard let ownerId = Auth.auth().currentUser?.uid else { throw NSError(domain: "NoUser", code: 0) }

        let db = Firestore.firestore()
        let storage = Storage.storage()
        let fileName = UUID().uuidString + ".jpg"
        let storageRef = storage.reference().child("Pets_images/\(fileName)")

        isUploading = true

        do {
            // Upload image
            _ = try await storageRef.putDataAsync(imageData)
            let downloadURL = try await storageRef.downloadURL()

            // Prepare data
            let petData: [String: Any] = [
                "id": UUID().uuidString,
                "name": name,
                "species": species,
                "breed": breed ?? NSNull(),
                "age": age ?? NSNull(),
                "bio": bio ?? NSNull(),
                "ownerId": ownerId,
                "petImageURL": downloadURL.absoluteString,
                "galleryURLs": [],
                "createdAt": Timestamp(),
                "updatedAt": Timestamp()
            ]

            try await db.collection("users")
                .document(ownerId)
                .collection("pets")
                .addDocument(data: petData)

            print("✅ Pet added successfully!")
        } catch {
            throw error
        }

        isUploading = false
    }
}
