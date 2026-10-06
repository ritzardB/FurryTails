//
//  FeedUploadViewModel.swift
//  My Pet
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import SwiftUI
import Foundation
import FirebaseAuth
import Combine
import FirebaseFirestoreCombineSwift
import FirebaseFirestore

enum FeedItemType: String, Codable {
    case post
    case pet
}

struct FeedItem: Identifiable, Codable {
    var id: String
    var type: FeedItemType
    var createdAt: Date
    var post: Post?
    var pet: Pet?
    var user: UserModel?
}

@MainActor
class FeedUploadViewModel: ObservableObject {

    // MARK: - Published Data

    @Published var posts: [Post] = []
    @Published var users: [UserModel] = []
    @Published var pets: [Pet] = []
    @Published var feedItems: [FeedItem] = []

    // MARK: - Services

    private let feedService = FeedService()
    private let userService = UserService()
    private let petService = PetService()

    // MARK: - Fetch Feed Data

    func fetchPosts() async {

        do {

            async let fetchedPosts = feedService.fetchPosts()
            async let fetchedUsers = feedService.fetchUsers()
            async let fetchedPets = feedService.fetchPets()

            let (
                postsResult,
                usersResult,
                petsResult
            ) = try await (
                fetchedPosts,
                fetchedUsers,
                fetchedPets
            )

            self.posts = postsResult
            self.users = usersResult
            self.pets = petsResult

            print(
                "📥 Feed loaded — Posts: \(posts.count) Users: \(users.count) Pets: \(pets.count)"
            )

            await combineFeed()

        } catch {

            print(
                "❌ Error fetching feed: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Combine Feed
    //
    // IMPORTANT:
    // Pets are fetched and stored in `pets` because other parts
    // of the application need them.
    //
    // However, pets are NOT inserted into `feedItems`.
    //
    // The social feed contains POSTS.
    // Pets are displayed in My Pets / Profile.
    //

    func combineFeed() async {

        var combined: [FeedItem] = []

        // --------------------------------------------------
        // Add POSTS to the feed
        // --------------------------------------------------

        for post in posts {

            let owner = users.first {
                $0.id == post.ownerId
            }

            combined.append(
                FeedItem(
                    id: post.id ?? UUID().uuidString,
                    type: .post,
                    createdAt: post.createdAt ?? Date(),
                    post: post,
                    pet: nil,
                    user: owner
                )
            )
        }

        // --------------------------------------------------
        // DO NOT add pets to the feed.
        //
        // Pets belong in:
        // - My Pets
        // - Profile
        // - Pet Gallery
        //
        // This prevents the same pet from appearing twice
        // when AddPetView also creates a social post.
        // --------------------------------------------------

        combined.sort {
            $0.createdAt > $1.createdAt
        }

        self.feedItems = combined

        print(
            "🎉 Combined feed built — total: \(feedItems.count)"
        )
    }

    // MARK: - Refresh Feed

    func refreshFeed() async {

        await fetchPosts()
    }
}
