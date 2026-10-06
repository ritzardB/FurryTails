//  FeedView.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import SwiftUI
import FirebaseFirestore

struct FeedView: View {

    @StateObject private var viewModel = FeedUploadViewModel()
    @State private var isLoading = true

    var body: some View {

        NavigationView {

            ScrollView {

                if isLoading {

                    ProgressView("Loading feed…")
                        .padding(.top, 100)

                } else {

                    VStack(
                        alignment: .leading,
                        spacing: 20
                    ) {

                        // MARK: - Horizontal User List

                        ScrollView(
                            .horizontal,
                            showsIndicators: false
                        ) {

                            HStack(spacing: 16) {

                                ForEach(
                                    viewModel.users
                                ) { user in

                                    VStack(spacing: 6) {

                                        AsyncImage(
                                            url: URL(
                                                string:
                                                    user.profileImageURL ?? ""
                                            )
                                        ) { image in

                                            image
                                                .resizable()
                                                .scaledToFill()

                                        } placeholder: {

                                            Image(
                                                systemName:
                                                    "person.circle.fill"
                                            )
                                            .resizable()
                                            .foregroundColor(
                                                .gray.opacity(0.4)
                                            )
                                        }
                                        .frame(
                                            width: 50,
                                            height: 50
                                        )
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerRadius: 12
                                            )
                                        )
                                        .shadow(radius: 3)

                                        Text(user.username)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .frame(width: 60)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }

                        // MARK: - Feed Posts

                        LazyVStack(spacing: 20) {

                            ForEach(
                                viewModel.feedItems
                            ) { item in

                                switch item.type {

                                case .post:

                                    if let post = item.post {

                                        PostCardView(
                                            post: post,
                                            user: item.user
                                        )
                                    }

                                case .pet:

                                    if let pet = item.pet {

                                        PetProfileView(
                                            pet: pet
                                        )
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }

            .navigationTitle("Furrytails 🐾")

            // MARK: - Initial Load

            .task {

                await viewModel.fetchPosts()

                isLoading = false
            }

            // MARK: - Pull To Refresh

            .refreshable {

                await viewModel.refreshFeed()
            }

            // MARK: - New Post

            .onReceive(
                NotificationCenter.default.publisher(
                    for: .postCreated
                )
            ) { _ in

                Task {

                    print("📣 Post created — refreshing feed")

                    await viewModel.refreshFeed()
                }
            }
        }
    }
}
