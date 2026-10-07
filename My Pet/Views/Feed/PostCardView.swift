//
//  PostCardView.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import SwiftUI
import AVKit
import UIKit
import FirebaseAuth

struct PostCardView: View {

    var post: Post
    var user: UserModel?

    @State private var likeCount: Int
    @State private var repostCount: Int
    @State private var shareCount: Int
    @State private var commentCount: Int
    
    @State private var isLiked = false
    @State private var isReposted = false

    @State private var showEditSheet = false
    @State private var showComments = false
    @State private var following = false

    @State private var selectedPhotoIndex = 0
    @State private var showPhotoViewer = false

    @State private var isLikeLoading = false
    @State private var isRepostLoading = false

    // MARK: - Init

    init(
        post: Post,
        user: UserModel? = nil
    ) {

        self.post = post
        self.user = user

        _likeCount = State(
            initialValue: post.likes
        )

        _repostCount = State(
            initialValue: post.reposts
        )
        
        _shareCount = State(
            initialValue: post.shares
        )

        _commentCount = State(
            initialValue: post.comments
        )
    }

    // MARK: - Body

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            // MARK: - Header

            HStack(spacing: 12) {

                AsyncImage(
                    url: URL(
                        string:
                            user?.profileImageURL ?? ""
                    )
                ) { image in

                    image
                        .resizable()

                } placeholder: {

                    Image(
                        systemName:
                            "person.circle.fill"
                    )
                    .resizable()
                    .foregroundColor(
                        .gray.opacity(0.3)
                    )
                }
                .scaledToFill()
                .frame(
                    width: 45,
                    height: 45
                )
                .clipShape(Circle())
                .shadow(radius: 4)

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text(
                        user?.username ??
                        "Unknown User"
                    )
                    .font(.headline)
                    .foregroundColor(.primary)

                    if let createdAt = post.createdAt {

                        Text(
                            createdAt,
                            style: .time
                        )
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                }

                Spacer()

                Menu {

                    Button {

                        following.toggle()

                    } label: {

                        Label(
                            following
                            ? "Unfollow"
                            : "Follow",
                            systemImage:
                                following
                                ? "person.crop.circle.badge.minus"
                                : "person.crop.circle.badge.plus"
                        )
                    }

                    Button {

                        showEditSheet.toggle()

                    } label: {

                        Label(
                            "Edit Post",
                            systemImage: "pencil"
                        )
                    }

                    Button {

                        Task {
                            await sharePost()
                        }

                    } label: {

                        Label(
                            "Share",
                            systemImage: "square.and.arrow.up"
                        )
                    }
                    // MARK: - Comment

                    Button {

                        showComments = true

                    } label: {

                        Label(
                            "\(commentCount)",
                            systemImage: "message"
                        )
                        .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)

                } label: {

                    Image(
                        systemName: "ellipsis"
                    )
                    .rotationEffect(
                        .degrees(90)
                    )
                    .foregroundColor(.gray)
                }
            }

            // MARK: - Media

            let photos: [String] = {

                if !post.imageURLs.isEmpty {

                    return post.imageURLs

                } else if
                    let imageURL = post.imageURL,
                    !imageURL.isEmpty
                {

                    return [imageURL]

                } else {

                    return []
                }
            }()

            if !photos.isEmpty {

                TabView(
                    selection:
                        $selectedPhotoIndex
                ) {

                    ForEach(
                        Array(
                            photos.enumerated()
                        ),
                        id: \.offset
                    ) { index, imageURL in

                        if let url = URL(
                            string: imageURL
                        ) {

                            AsyncImage(
                                url: url
                            ) { phase in

                                switch phase {

                                case .empty:

                                    ZStack {

                                        Color.gray.opacity(
                                            0.08
                                        )

                                        ProgressView()
                                    }

                                case .success(let image):

                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(
                                            maxWidth:
                                                .infinity,
                                            maxHeight:
                                                .infinity
                                        )
                                        .background(
                                            Color.black
                                                .opacity(0.03)
                                        )

                                case .failure:

                                    ZStack {

                                        Color.gray.opacity(
                                            0.08
                                        )

                                        VStack(
                                            spacing: 8
                                        ) {

                                            Image(
                                                systemName:
                                                    "photo"
                                            )
                                            .font(
                                                .largeTitle
                                            )
                                            .foregroundColor(
                                                .gray
                                            )

                                            Text(
                                                "Unable to load image"
                                            )
                                            .font(
                                                .caption
                                            )
                                            .foregroundColor(
                                                .gray
                                            )
                                        }
                                    }

                                @unknown default:

                                    EmptyView()
                                }
                            }
                            .frame(
                                maxWidth: .infinity
                            )
                            .tag(index)
                            .contentShape(
                                Rectangle()
                            )
                            .onTapGesture {

                                selectedPhotoIndex =
                                    index

                                showPhotoViewer = true
                            }
                        }
                    }
                }
                .frame(
                    maxWidth: .infinity
                )
                .frame(height: 300)
                .tabViewStyle(
                    .page(
                        indexDisplayMode:
                            .automatic
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 8
                    )
                )
            }

            // MARK: - Caption

            if !post.caption.isEmpty {

                Text(post.caption)
                    .font(.body)
                    .padding(.top, 5)
            }

            Divider()

            // MARK: - Post Actions

            HStack {

                // ⭐ LIKE

                Button {

                    Task {
                        await toggleLike()
                    }

                } label: {

                    Label(
                        "\(likeCount)",
                        systemImage:
                            isLiked
                            ? "star.fill"
                            : "star"
                    )
                    .foregroundColor(
                        isLiked
                        ? FurryTailsTheme.orange
                        : .gray
                    )
                }
                .disabled(isLikeLoading)
                .frame(
                    maxWidth: .infinity
                )

                // 🔁 REPOST

                Button {

                    Task {
                        await toggleRepost()
                    }

                } label: {

                    Label(
                        "\(repostCount)",
                        systemImage:
                            "arrow.2.circlepath"
                    )
                    .foregroundColor(
                        isReposted
                        ? .green
                        : .gray
                    )
                }
                .disabled(isRepostLoading)
                .frame(
                    maxWidth: .infinity
                )

                // ↗️ SHARE

                Button {

                    Task {
                        await sharePost()
                    }

                } label: {

                    Label(
                        "\(shareCount)",
                        systemImage: "square.and.arrow.up"
                    )
                    .foregroundColor(.blue)

                }
                .frame(maxWidth: .infinity)

                // 💬 COMMENT

                Button {

                    showComments = true

                } label: {

                    Label(
                        "\(commentCount)",
                        systemImage:
                            "message"
                    )
                    .foregroundColor(
                        .gray
                    )
                }
                .frame(
                    maxWidth: .infinity
                )
            }
            .font(.subheadline)
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            FurryTailsTheme.cardBackground
        )
        .cornerRadius(12)
        .shadow(
            color: .gray.opacity(0.2),
            radius: 5,
            x: 0,
            y: 2
        )

        // MARK: - Edit Post

        .sheet(
            isPresented:
                $showEditSheet
        ) {

            EditPostView(
                post: post
            )
        }

        // MARK: - Comments

        .sheet(
            isPresented:
                $showComments
        ) {

            PostCommentsView(
                postId:
                    post.id ?? "",
                commentCount:
                    $commentCount
            )
        }

        // MARK: - Load Interaction State

        .task {

            await loadInteractionState()
        }
    }

    // MARK: - Load Interaction State

    private func loadInteractionState() async {

        guard post.id != nil else {
            return
        }

        do {

            async let liked =
                PostInteractionService.shared
                    .checkLike(
                        postId:
                            post.id!
                    )

            async let reposted =
                PostInteractionService.shared
                    .checkRepost(
                        postId:
                            post.id!
                    )

            let (
                likedResult,
                repostedResult
            ) = try await (
                liked,
                reposted
            )

            isLiked =
                likedResult

            isReposted =
                repostedResult

        } catch {

            print(
                "❌ Failed to load post interaction state:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Toggle Like

    private func toggleLike() async {

        guard let postId = post.id else {
            return
        }

        isLikeLoading = true

        defer {
            isLikeLoading = false
        }

        do {

            let liked =
                try await
                PostInteractionService.shared
                    .toggleLike(
                        postId: postId
                    )

            isLiked = liked

            if liked {

                likeCount += 1

            } else {

                likeCount =
                    max(
                        0,
                        likeCount - 1
                    )
            }

        } catch {

            print(
                "❌ Like failed:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Toggle Repost

    private func toggleRepost() async {

        guard let postId = post.id else {
            return
        }

        isRepostLoading = true

        defer {
            isRepostLoading = false
        }

        do {

            let reposted =
                try await
                PostInteractionService.shared
                    .toggleRepost(
                        postId: postId
                    )

            isReposted =
                reposted

            if reposted {

                repostCount += 1

            } else {

                repostCount =
                    max(
                        0,
                        repostCount - 1
                    )
            }

        } catch {

            print(
                "❌ Repost failed:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Share

    private func sharePost() async {

        guard let postId = post.id else {
            return
        }

        do {

            // Record share in Firestore
            try await PostInteractionService.shared
                .recordShare(
                    postId: postId
                )

            // Update local UI
            shareCount += 1

            // Open iOS share sheet
            let items: [Any] = [

                "Check out this post on FurryTails! 🐾",

                post.caption
            ]

            let activityVC =
                UIActivityViewController(
                    activityItems: items,
                    applicationActivities: nil
                )

            if let windowScene =
                UIApplication.shared
                    .connectedScenes
                    .compactMap({
                        $0 as? UIWindowScene
                    })
                    .first,

               let rootVC =
                windowScene
                    .windows
                    .first(
                        where: {
                            $0.isKeyWindow
                        }
                    )?
                    .rootViewController {

                rootVC.present(
                    activityVC,
                    animated: true
                )
            }

        } catch {

            print(
                "❌ Share failed:",
                error.localizedDescription
            )
        }
    }
    
//    // MARK: - Comment
//
//    Button {
//
//        showComments = true
//
//    } label: {
//
//        Label(
//            "\(commentCount)",
//            systemImage: "message"
//        )
//        .foregroundColor(.gray)
//    }
//    .frame(maxWidth: .infinity)

}
