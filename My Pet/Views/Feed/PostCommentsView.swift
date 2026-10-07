import SwiftUI
import FirebaseAuth
import PhotosUI
import UIKit

struct PostCommentsView: View {

    let postId: String

    @Binding var commentCount: Int

    @Environment(\.dismiss)
    private var dismiss

    @State private var comments: [PostComment] = []
    @State private var newComment = ""

    @State private var isLoading = true
    @State private var isPosting = false

    // MARK: - Composer State

    @State private var showActionMenu = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false

    @State private var selectedPhoto: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?

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

                        Image(systemName: "message")
                            .font(.system(size: 45))
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

                            ForEach(comments) { comment in

                                commentRow(comment)
                            }
                        }
                        .padding()
                    }
                }

                // MARK: - Photo Preview

                if let selectedPhoto {

                    HStack {

                        ZStack(alignment: .topTrailing) {

                            Image(uiImage: selectedPhoto)
                                .resizable()
                                .scaledToFill()
                                .frame(
                                    width: 90,
                                    height: 90
                                )
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 12
                                    )
                                )

                            Button {

                                removeSelectedPhoto()

                            } label: {

                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.55))
                                    )
                            }
                            .offset(x: 6, y: -6)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                // MARK: - Comment Input

                HStack(
                    alignment: .bottom,
                    spacing: 8
                ) {

                    // MARK: Plus Button

                    Menu {

                        Button {

                            showPhotoPicker = true

                        } label: {

                            Label(
                                "Choose Photo",
                                systemImage: "photo"
                            )
                        }

                        Button {

                            showCamera = true

                        } label: {

                            Label(
                                "Take Photo",
                                systemImage: "camera"
                            )
                        }

                        Divider()

                        Button {

                            print("🐾 Pet Moment selected")

                        } label: {

                            Label(
                                "Pet Moment",
                                systemImage: "pawprint.fill"
                            )
                        }

                    } label: {

                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(
                                FurryTailsTheme.orange
                            )
                    }
                    .disabled(isPosting)

                    // MARK: Camera Button

                    Button {

                        showCamera = true

                    } label: {

                        Image(systemName: "camera.fill")
                            .font(.system(size: 20))
                            .foregroundColor(
                                FurryTailsTheme.orange
                            )
                            .frame(
                                width: 34,
                                height: 34
                            )
                    }
                    .disabled(isPosting)

                    // MARK: Text Field

                    TextField(
                        "Write a comment...",
                        text: $newComment,
                        axis: .vertical
                    )
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)

                    // MARK: Send Button

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
            .navigationBarTitleDisplayMode(.inline)
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

            // MARK: - Photo Picker

            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images
            )

            // MARK: - Photo Picker Result

            .onChange(
                of: selectedPhotoItem
            ) { _, newItem in

                guard let newItem else {
                    return
                }

                Task {

                    do {

                        if let data =
                            try await newItem.loadTransferable(
                                type: Data.self
                            ),
                            let image = UIImage(
                                data: data
                            ) {

                            await MainActor.run {

                                selectedPhoto = image
                            }
                        }

                    } catch {

                        print(
                            "❌ Failed to load selected photo:",
                            error.localizedDescription
                        )
                    }
                }
            }

            // MARK: - Camera

            .sheet(
                isPresented: $showCamera
            ) {

                CameraPicker(
                    selectedImage: $selectedPhoto
                )
                .ignoresSafeArea()
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
                url: URL(
                    string:
                        comment.profileImageURL ?? ""
                )
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
                            .tint(
                                FurryTailsTheme.orange
                            )
                    }

                case .success(let image):

                    image
                        .resizable()
                        .scaledToFill()

                case .failure:

                    Image(
                        systemName:
                            "person.circle.fill"
                    )
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(
                        FurryTailsTheme.orange
                            .opacity(0.6)
                    )

                @unknown default:

                    Image(
                        systemName:
                            "person.circle.fill"
                    )
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(
                        FurryTailsTheme.orange
                            .opacity(0.6)
                    )
                }
            }
            .frame(
                width: 42,
                height: 42
            )
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

            print(
                "👤 Comment user: \(currentUser.username)"
            )

            print(
                "🆔 Comment UID: \(uid)"
            )

            print(
                "🖼️ Comment profile URL: \(currentUser.profileImageURL ?? "NIL")"
            )

            // Current comment system remains unchanged.
            // Photo upload will be connected in the next step.

            try await
                PostInteractionService.shared
                    .addComment(
                        postId: postId,
                        text: text,
                        username: currentUser.username,
                        profileImageURL:
                            currentUser.profileImageURL
                    )

            newComment = ""

            removeSelectedPhoto()

            commentCount += 1

            await loadComments()

            print(
                "💬 Comment added successfully"
            )

        } catch {

            print(
                "❌ Failed to add comment:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Remove Photo

    private func removeSelectedPhoto() {

        selectedPhoto = nil
        selectedPhotoItem = nil
    }
}

// MARK: - Camera Picker

struct CameraPicker: UIViewControllerRepresentable {

    @Binding var selectedImage: UIImage?

    @Environment(\.dismiss)
    private var dismiss

    func makeUIViewController(
        context: Context
    ) -> UIImagePickerController {

        let picker =
            UIImagePickerController()

        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator

        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {
    }

    func makeCoordinator()
        -> Coordinator {

        Coordinator(self)
    }

    final class Coordinator:
        NSObject,
        UIImagePickerControllerDelegate,
        UINavigationControllerDelegate {

        private let parent: CameraPicker

        init(_ parent: CameraPicker) {

            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info:
                [UIImagePickerController.InfoKey: Any]
        ) {

            if let image =
                info[
                    .originalImage
                ] as? UIImage {

                parent.selectedImage = image
            }

            parent.dismiss()
        }

        func imagePickerControllerDidCancel(
            _ picker: UIImagePickerController
        ) {

            parent.dismiss()
        }
    }
}
