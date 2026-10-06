//
//  PostService.swift
//  My Pet
//
//  Created by Richard on 2025-10-31.
//

import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseStorage
import FirebaseAuth
import Combine

final class PostService {
    static let shared = PostService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Fetch all posts from /posts
    func fetchAllPosts() async throws -> [Post] {
        let snapshot = try await db.collection("posts")
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Post.self) }
    }



    // MARK: - Fetch posts for one user
    func fetchUserPosts(for userId: String) async throws -> [Post] {
        let snapshot = try await db.collection("posts")
            .whereField("ownerId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap {
            try? $0.data(as: Post.self)
        }
    }
}
