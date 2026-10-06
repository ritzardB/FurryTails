//
//  PostCardView.swift
//  My Pet
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import SwiftUI
import AVKit

struct PostCardView: View {
    var post: Post
    var user: UserModel?
    
    @State private var likeCount: Int
    @State private var repostCount: Int
    @State private var shareCount = 0
    @State private var commentCount: Int

    @State private var isLiked = false
    @State private var isReposted = false
    @State private var showEditSheet = false
    @State private var following = false
    
    @State private var selectedPhotoIndex = 0
    @State private var showPhotoViewer = false

    // MARK: - Init
    init(post: Post, user: UserModel? = nil) {
        self.post = post
        self.user = user


        // Initialize state counts from the post model
        _likeCount = State(initialValue: post.likes)
        _repostCount = State(initialValue: post.reposts)
        _commentCount = State(initialValue: post.comments)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // 🐾 Header Section
        HStack(spacing: 12) {
            // Profile image + username
                AsyncImage(url: URL(string: user?.profileImageURL ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray.opacity(0.3))
                }
                .scaledToFill()
                .frame(width: 45, height: 45)
                .clipShape(Circle())
                .shadow(radius: 4)

                VStack(alignment: .leading, spacing: 2) {
                    Text(user?.username ?? "Unknown User")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(post.createdAt!, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Menu button
                Menu {
                    Button {
                        following.toggle()
                    } label: {
                        Label(following ? "Unfollow" : "Follow",
                              systemImage: following ? "person.crop.circle.badge.minus" : "person.crop.circle.badge.plus")
                    }

                    Button {
                        showEditSheet.toggle()
                    } label: {
                        Label("Edit Post", systemImage: "pencil")
                    }

                    Button {
                        sharePost()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .foregroundColor(.gray)
                }
            }

            // 🖼️ Media content
            let photos: [String] = {
                if !post.imageURLs.isEmpty {
                    return post.imageURLs
                } else if let imageURL = post.imageURL, !imageURL.isEmpty {
                    return [imageURL]
                } else {
                    return []
                }
            }()

            if !photos.isEmpty {

                TabView(selection: $selectedPhotoIndex) {

                    ForEach(
                        Array(photos.enumerated()),
                        id: \.offset
                    ) { index, imageURL in

                        if let url = URL(string: imageURL) {

                            AsyncImage(url: url) { phase in

                                switch phase {

                                case .empty:
                                    ZStack {
                                        Color.gray.opacity(0.08)
                                        ProgressView()
                                    }

                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(
                                            maxWidth: .infinity,
                                            maxHeight: .infinity
                                        )
                                        .background(
                                            Color.black.opacity(0.03)
                                        )

                                case .failure:
                                    ZStack {
                                        Color.gray.opacity(0.08)

                                        VStack(spacing: 8) {
                                            Image(systemName: "photo")
                                                .font(.largeTitle)
                                                .foregroundColor(.gray)

                                            Text("Unable to load image")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }

                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .tag(index)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedPhotoIndex = index
                                showPhotoViewer = true
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .clipShape(
                    RoundedRectangle(cornerRadius: 8)
                )
            }

            // 📝 Caption
            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(.body)
                    .padding(.top, 5)
            }

            Divider()
            
            // ❤️ Post Actions
            HStack {
                Button {
                    isLiked.toggle()
                    likeCount += isLiked ? 1 : -1
                } label: {
                    Label("\(likeCount)", systemImage: isLiked ? "star.fill" : "star")
                        .foregroundColor(isLiked ? .red : .gray)
                }
                .frame(maxWidth: .infinity)

                Button {
                    isReposted.toggle()
                    repostCount += isReposted ? 1 : -1
                } label: {
                    Label("\(repostCount)", systemImage: "arrow.2.circlepath")
                        .foregroundColor(isReposted ? .green : .gray)
                }
                .frame(maxWidth: .infinity)

                Button {
                    shareCount += 1
                    sharePost()
                } label: {
                    Label("\(shareCount)", systemImage: "square.and.arrow.up")
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)

                Button {
                    commentCount += 1
                } label: {
                    Label("\(commentCount)", systemImage: "message")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            }
            .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showEditSheet) {
            EditPostView(post: post)
        }
    }

    // MARK: - Share Action
    private func sharePost() {
        let items: [Any] = [post.caption]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
