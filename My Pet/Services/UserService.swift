//
//  UserService.swift
//  My Pet
//
//  Created by Richard Balabarcon on 29/10/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine


@MainActor
class UserService: ObservableObject {
    private var db = Firestore.firestore()
    
    // Create user
    func createUser(_ user: UserModel) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "UserService",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey: "No authenticated user found."
                ]
            )
        }

        let document = db.collection("users").document(uid)
        let data = try Firestore.Encoder().encode(user)

        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in

            document.setData(data) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    // Fetch all users — if you ever need to show who posted what
    func fetchUsers(by uid: String) async throws -> [UserModel] {
        let snapshot = try await db.collection("users").getDocuments()
        let users = snapshot.documents.compactMap { document in
            try? document.data(as: UserModel.self)
        }
        return users
    }
    
    // Fetch single user by ID (useful when uploading a post)
    func fetchUser(by id: String) async throws -> UserModel? {
        let doc = try await db.collection("users").document(id).getDocument()
        return try? doc.data(as: UserModel.self)
    }
}
