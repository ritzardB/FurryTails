
//
//  PostCommentsView.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import SwiftUI
import FirebaseAuth

struct PostCommentsView: View {

    let postId: String

    @Binding var commentCount: Int

    @Environment(\.dismiss)
    private var dismiss

    @State private var comments: [PostComment] = []

    @State private var newComment = ""

    @State private var isLoading = true
    @State private var isPosting = false

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                // MARK: - Comments

                if isLoading {

                    ProgressView("Loading comments...")
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )

                } else if comments.isEmpty {

                    VStack(spacing: 12) {

                        Image(
                            systemName: "message"
                        )
                        .font(
                            .system(size: 45)
                        )
                        .foregroundColor(
                            FurryTailsTheme.orange
                        )

                        Text("No comments yet")
                            .font(.headline)

                        Text(
                            "Be the first to comment! 🐾"
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )

                } else {

                    ScrollView {

                        LazyVStack(
                            alignment: .leading,
                            spacing: 16
                        ) {

                            ForEach(
                                comments
                            ) { comment in

                                commentRow(
                                    comment
                                )
                            }
                        }
                        .padding()
                    }
                }

                // MARK: - Comment Input

                HStack(
                    alignment: .bottom,
                    spacing: 10
                ) {

                    TextField(
                        "Write a comment...",
                        text: $newComment,
                        axis: .vertical
                    )
                    .textFieldStyle(
                        .roundedBorder
                    )
                    .lineLimit(1...4)

                    Button {

                        Task {
                            await addComment()
                        }

                    } label: {

                        if isPosting {

                            ProgressView()
                                .frame(
                                    width: 36,
                                    height: 36
                                )

                        } else {

                            Image(
                                systemName:
                                    "paperplane.fill"
                            )
                            .foregroundColor(
                                FurryTailsTheme.orange
                            )
                            .frame(
                                width: 36,
                                height: 36
                            )
                        }
                    }
                    .disabled(
                        newComment
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                        || isPosting
                    )
                }
                .padding()
                .background(
                    FurryTailsTheme.cardBackground
                )
            }
            .background(
                FurryTailsTheme.background
            )
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {

                ToolbarItem(
                    placement:
                        .navigationBarTrailing
                ) {

                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {

                await loadComments()
            }
        }
    }

    // MARK: - Comment Row

    @ViewBuilder
    private func commentRow(
        _ comment: PostComment
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 10
        ) {

            AsyncImage(
                url: URL(string: comment.profileImageURL ?? "")
            ) { phase in

                switch phase {

                case .empty:
                    ZStack {
                        Circle()
                            .fill(
                                FurryTailsTheme.orange
                                    .opacity(0.12)
                            )

                        ProgressView()
                            .tint(FurryTailsTheme.orange)
                    }

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(
                            FurryTailsTheme.orange.opacity(0.6)
                        )

                @unknown default:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(
                            FurryTailsTheme.orange.opacity(0.6)
                        )
                }
            }
            .frame(width: 42, height: 42)
            .clipShape(Circle())

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(comment.username)
                    .font(
                        .subheadline.bold()
                    )
                    .foregroundColor(
                        FurryTailsTheme.primaryText
                    )

                Text(comment.text)
                    .font(.body)
                    .foregroundColor(
                        FurryTailsTheme.primaryText
                    )

                if let date = comment.createdAt {
                    Text(
                        date.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )
                    .font(.caption)
                    .foregroundColor(
                        FurryTailsTheme.secondaryText
                    )
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Load Comments

    private func loadComments() async {

        guard !postId.isEmpty else {
            isLoading = false
            return
        }

        do {

            comments =
                try await
                PostInteractionService.shared
                    .fetchComments(
                        postId: postId
                    )

        } catch {

            print(
                "❌ Failed to load comments:",
                error.localizedDescription
            )
        }

        isLoading = false
    }

    // MARK: - Add Comment

    private func addComment() async {

        guard
            let uid =
                Auth.auth()
                    .currentUser?
                    .uid
        else {

            print(
                "❌ No authenticated user"
            )

            return
        }

        let text =
            newComment
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard !text.isEmpty else {
            return
        }

        isPosting = true

        defer {
            isPosting = false
        }

        do {

            let currentUser =
                try await
                AuthService.loadUser(
                    uid: uid
                )
            
            print("👤 Comment user: \(currentUser.username)")
            print("🆔 Comment UID: \(uid)")
            print("🖼️ Comment profile URL: \(currentUser.profileImageURL ?? "NIL")")

            try await PostInteractionService.shared.addComment(
                postId: postId,
                text: text,
                username: currentUser.username,
                profileImageURL: currentUser.profileImageURL
            )
            
            newComment = ""

            commentCount += 1

            await loadComments()

            print("💬 Comment added successfully")

        } catch {

            print(
                "❌ Failed to add comment:",
                error.localizedDescription
            )
        }
    }
}
