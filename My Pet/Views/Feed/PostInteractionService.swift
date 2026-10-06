//
//  PostInteractionService.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class PostInteractionService {

    static let shared = PostInteractionService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Current User

    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    // MARK: - Like

    func toggleLike(
        postId: String
    ) async throws -> Bool {

        guard let uid = currentUserId else {
            throw interactionError(
                "You must be signed in to like a post."
            )
        }

        let postRef = db
            .collection("posts")
            .document(postId)

        let likeRef = postRef
            .collection("likes")
            .document(uid)

        let snapshot = try await likeRef.getDocument()

        let isCurrentlyLiked = snapshot.exists

        let batch = db.batch()

        if isCurrentlyLiked {

            batch.deleteDocument(likeRef)

            batch.updateData(
                [
                    "likes": FieldValue.increment(Int64(-1))
                ],
                forDocument: postRef
            )

        } else {

            batch.setData(
                [
                    "userId": uid,
                    "createdAt": FieldValue.serverTimestamp()
                ],
                forDocument: likeRef
            )

            batch.updateData(
                [
                    "likes": FieldValue.increment(Int64(1))
                ],
                forDocument: postRef
            )
        }

        try await batch.commit()

        return !isCurrentlyLiked
    }

    // MARK: - Check Like

    func checkLike(
        postId: String
    ) async throws -> Bool {

        guard let uid = currentUserId else {
            return false
        }

        let snapshot = try await db
            .collection("posts")
            .document(postId)
            .collection("likes")
            .document(uid)
            .getDocument()

        return snapshot.exists
    }

    // MARK: - Repost

    func toggleRepost(
        postId: String
    ) async throws -> Bool {

        guard let uid = currentUserId else {
            throw interactionError(
                "You must be signed in to repost."
            )
        }

        let postRef = db
            .collection("posts")
            .document(postId)

        let repostRef = postRef
            .collection("reposts")
            .document(uid)

        let snapshot = try await repostRef.getDocument()

        let isCurrentlyReposted = snapshot.exists

        let batch = db.batch()

        if isCurrentlyReposted {

            batch.deleteDocument(repostRef)

            batch.updateData(
                [
                    "reposts": FieldValue.increment(Int64(-1))
                ],
                forDocument: postRef
            )

        } else {

            batch.setData(
                [
                    "userId": uid,
                    "createdAt": FieldValue.serverTimestamp()
                ],
                forDocument: repostRef
            )

            batch.updateData(
                [
                    "reposts": FieldValue.increment(Int64(1))
                ],
                forDocument: postRef
            )
        }

        try await batch.commit()

        return !isCurrentlyReposted
    }

    // MARK: - Check Repost

    func checkRepost(
        postId: String
    ) async throws -> Bool {

        guard let uid = currentUserId else {
            return false
        }

        let snapshot = try await db
            .collection("posts")
            .document(postId)
            .collection("reposts")
            .document(uid)
            .getDocument()

        return snapshot.exists
    }

    // MARK: - Add Comment

    func addComment(
        postId: String,
        text: String,
        username: String,
        profileImageURL: String?
    ) async throws {

        guard let uid = currentUserId else {
            throw interactionError(
                "You must be signed in to comment."
            )
        }

        let trimmedText = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedText.isEmpty else {
            return
        }

        let postRef = db
            .collection("posts")
            .document(postId)

        let commentRef = postRef
            .collection("comments")
            .document()

        let batch = db.batch()
        
        print("💾 Saving comment")
        print("   userId: \(uid)")
        print("   username: \(username)")
        print("   profileImageURL: \(profileImageURL ?? "NIL")")
        print("   text: \(trimmedText)")

        // Create comment
        batch.setData(
            [
                "id": commentRef.documentID,
                "userId": uid,
                "username": username,
                "profileImageURL": profileImageURL ?? "",
                "text": trimmedText,
                "createdAt": FieldValue.serverTimestamp()
            ],
            forDocument: commentRef
        )

        // Increment post comment counter
        batch.updateData(
            [
                "comments": FieldValue.increment(Int64(1))
            ],
            forDocument: postRef
        )

        try await batch.commit()
    }

    // MARK: - Fetch Comments

    func fetchComments(
        postId: String
    ) async throws -> [PostComment] {

        let snapshot = try await db
            .collection("posts")
            .document(postId)
            .collection("comments")
            .order(
                by: "createdAt",
                descending: false
            )
            .getDocuments()

        return snapshot.documents.compactMap { document in

            let data = document.data()

            guard
                let userId = data["userId"] as? String,
                let username = data["username"] as? String,
                let text = data["text"] as? String
            else {
                return nil
            }

            let profileImageURL =
                data["profileImageURL"] as? String

            let createdAt =
                (data["createdAt"] as? Timestamp)?
                .dateValue()

            return PostComment(
                id: document.documentID,
                userId: userId,
                username: username,
                profileImageURL: profileImageURL,
                text: text,
                createdAt: createdAt
            )
        }
    }

    // MARK: - Error

    private func interactionError(
        _ message: String
    ) -> NSError {

        NSError(
            domain: "PostInteractionService",
            code: 1001,
            userInfo: [
                NSLocalizedDescriptionKey: message
            ]
        )
    }
}

// MARK: - Post Comment Model

struct PostComment: Identifiable {

    let id: String
    let userId: String
    let username: String
    let profileImageURL: String?
    let text: String
    let createdAt: Date?
}
