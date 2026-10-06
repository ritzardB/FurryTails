//
//  ProfileViewModel.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//
import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: UserModel?
    @Published var userPosts: [Post] = []
    @Published var isFollowing = false
    @Published var isLoading = false


    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Fetch User Profile
    func fetchUserProfile(ownerId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let doc = try await db.collection("users").document(ownerId).getDocument()
            user = try doc.data(as: UserModel.self)
        } catch {
            print("❌ Error fetching user profile: \(error.localizedDescription)")
        }
    }

    // MARK: - Fetch User Posts
    func fetchUserPosts(ownerId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try await db.collection("posts")
                .whereField("ownerId", isEqualTo: ownerId)
                .order(by: "createdAt", descending: true)
                .getDocuments()

            userPosts = snapshot.documents.compactMap { document in
                try? document.data(as: Post.self)
            }
        } catch {
            print("❌ Error fetching user posts: \(error.localizedDescription)")
        }
    }

    // MARK: - Follow / Unfollow User
    func followUser(currentownerId: String, targetUser: UserModel) async {
        guard let targetownerId = targetUser.id else { return }

        do {
            // Add target to current user's "following" list
            try await db.collection("users").document(currentownerId)
                .updateData([
                    "following": FieldValue.arrayUnion([targetownerId])
                ])

            // Add current user to target user's "followers" list
            try await db.collection("users").document(targetownerId)
                .updateData([
                    "followers": FieldValue.arrayUnion([currentownerId])
                ])

            isFollowing = true
        } catch {
            print("❌ Error following user: \(error.localizedDescription)")
        }
    }

    func unfollowUser(currentownerId: String, targetUser: UserModel) async {
        guard let targetownerId = targetUser.id else { return }

        do {
            try await db.collection("users").document(currentownerId)
                .updateData([
                    "following": FieldValue.arrayRemove([targetownerId])
                ])

            try await db.collection("users").document(targetownerId)
                .updateData([
                    "followers": FieldValue.arrayRemove([currentownerId])
                ])

            isFollowing = false
        } catch {
            print("❌ Error unfollowing user: \(error.localizedDescription)")
        }
    }
}
