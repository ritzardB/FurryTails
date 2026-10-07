//
//  LivePhotoView.swift
//  My Pet
//
//  Created by Richard Balabarcon on 07/10/2026.
//

import SwiftUI
import PhotosUI
import AVKit
import Photos

struct LivePhotoView: View {

    // MARK: - Live Sessions

    @StateObject private var viewModel = LiveSessionViewModel()

    // MARK: - Existing Live Content

    @State private var livePhoto: PHLivePhoto?
    @State private var recordedVideoURL: URL?

    @State private var showVideoPlayer = false
    @State private var showPicker = false
    @State private var pickerItem: PhotosPickerItem?

    // MARK: - UI State

    @State private var showFloatingButtons = true
    @State private var showStartLiveSheet = false
    @State private var liveTitle = ""

    var body: some View {
        NavigationStack {
            ZStack {
                FurryTailsTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {

                        // MARK: Header

                        header

                        // MARK: Live Now Users

                        liveNowSection

                        // MARK: Selected Live Session

                        selectedSessionSection

                        // MARK: Existing Live Photo / Video Tools

                        existingContentSection
                    }
                    .padding(.bottom, 24)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadLiveSessions()
            }
            .sheet(isPresented: $showStartLiveSheet) {
                startLiveSheet
            }
            .sheet(isPresented: $showPicker) {
                PhotosPicker(
                    selection: $pickerItem,
                    matching: .livePhotos,
                    photoLibrary: .shared()
                ) {
                    Text("Select Live Photo")
                }
                .onChange(of: pickerItem) { _, newItem in
                    loadLivePhoto(from: newItem)
                }
            }
            .sheet(isPresented: $showVideoPlayer) {
                VideoCaptureView(videoURL: $recordedVideoURL)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Live Now")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(FurryTailsTheme.primaryText)

                Text(
                    viewModel.hasLiveSessions
                    ? "\(viewModel.liveSessions.count) live now"
                    : "No one is live right now"
                )
                .font(.subheadline)
                .foregroundColor(FurryTailsTheme.secondaryText)
            }

            Spacer()

            if viewModel.myLiveSession != nil {
                Button {
                    Task {
                        await viewModel.endLiveSession()
                    }
                } label: {
                    Label("End Live", systemImage: "stop.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.red)
            } else {
                Button {
                    liveTitle = ""
                    showStartLiveSheet = true
                } label: {
                    Label("Go Live", systemImage: "video.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(FurryTailsTheme.orange)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Live Now Section

    private var liveNowSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Live Session is Up")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(FurryTailsTheme.primaryText)
                .padding(.horizontal)

            if viewModel.isLoading && viewModel.liveSessions.isEmpty {

                HStack {
                    Spacer()

                    ProgressView("Loading live sessions...")

                    Spacer()
                }
                .padding(.vertical, 20)

            } else if viewModel.liveSessions.isEmpty {

                emptyLiveState

            } else {

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 14) {

                        ForEach(viewModel.liveSessions) { session in
                            LiveSessionAvatar(
                                session: session,
                                isSelected: viewModel.selectedSession?.id == session.id,
                                isCurrentUser: session.hostId == viewModel.currentUserId
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectSession(session)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Empty Live State

    private var emptyLiveState: some View {
        VStack(spacing: 10) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 38))
                .foregroundColor(FurryTailsTheme.orange.opacity(0.7))

            Text("No Live Sessions")
                .font(.headline)
                .foregroundColor(FurryTailsTheme.primaryText)

            Text("When someone goes live, they'll appear here.")
                .font(.subheadline)
                .foregroundColor(FurryTailsTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal)
    }

    // MARK: - Selected Session

    private var selectedSessionSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            if let session = viewModel.selectedSession {

                VStack(spacing: 0) {

                    // Main Live Content Area

                    ZStack(alignment: .bottom) {

                        selectedContent

                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.75)
                            ],
                            startPoint: .center,
                            endPoint: .bottom
                        )

                        sessionOverlay(session)
                    }
                    .frame(height: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 6)
                }
                .padding(.horizontal)

            } else {

                noSelectedSessionView
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Selected Content

    private var selectedContent: some View {

        Group {
            if let livePhoto = livePhoto {

                LivePhotoPlayerView(livePhoto: livePhoto)
                    .frame(maxWidth: .infinity)
                    .frame(height: 420)
                    .clipped()

            } else if let videoURL = recordedVideoURL {

                VideoPlayer(
                    player: AVPlayer(url: videoURL)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 420)

            } else {

                ZStack {
                    LinearGradient(
                        colors: [
                            FurryTailsTheme.orange.opacity(0.9),
                            FurryTailsTheme.orangeLight.opacity(0.75)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    VStack(spacing: 12) {

                        Image(systemName: "video.fill")
                            .font(.system(size: 46))
                            .foregroundColor(.white)

                        Text("Live Stream")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Streaming will be connected here.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
            }
        }
    }

    // MARK: - Session Overlay

    private func sessionOverlay(_ session: LiveSession) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            HStack(spacing: 10) {

                profileImage(
                    url: session.hostProfileImageURL,
                    size: 42
                )

                VStack(alignment: .leading, spacing: 2) {

                    HStack(spacing: 6) {
                        Text(session.hostUsername)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("LIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }

                    if !session.title.isEmpty {
                        Text(session.title)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                }

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: "eye.fill")

                    Text("\(session.viewerCount)")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            }

            HStack(spacing: 12) {

                Button {
                    // Comments will be connected in a later milestone.
                } label: {
                    Image(systemName: "bubble.right.fill")
                }

                Button {
                    // Reactions will be connected in a later milestone.
                } label: {
                    Image(systemName: "heart.fill")
                }

                Button {
                    // Sharing will be connected in a later milestone.
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }

                Spacer()
            }
            .font(.title3)
            .foregroundColor(.white)
        }
        .padding()
    }

    // MARK: - No Selected Session

    private var noSelectedSessionView: some View {
        VStack(spacing: 12) {

            Image(systemName: "video.slash")
                .font(.system(size: 42))
                .foregroundColor(FurryTailsTheme.secondaryText)

            Text("No Live Session Selected")
                .font(.headline)
                .foregroundColor(FurryTailsTheme.primaryText)

            Text("Select someone from Live Now to watch their session.")
                .font(.subheadline)
                .foregroundColor(FurryTailsTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
        .background(
            FurryTailsTheme.cardBackground
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 20)
        )
    }

    // MARK: - Existing Content

    private var existingContentSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Live Moments")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(FurryTailsTheme.primaryText)

            HStack(spacing: 12) {

                Button {
                    showPicker = true
                } label: {
                    Label(
                        "Live Photo",
                        systemImage: "photo.on.rectangle"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    showVideoPlayer = true
                } label: {
                    Label(
                        "Record",
                        systemImage: "camera.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Start Live Sheet

    private var startLiveSheet: some View {

        NavigationStack {

            VStack(spacing: 24) {

                Image(systemName: "video.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(FurryTailsTheme.orange)

                Text("Start a Live Session")
                    .font(.title2)
                    .fontWeight(.bold)

                TextField(
                    "What are you going to share?",
                    text: $liveTitle
                )
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

                Button {

                    showStartLiveSheet = false

                    Task {
                        await viewModel.startLiveSession(
                            title: liveTitle
                        )
                    }

                } label: {

                    Label(
                        "Start Live",
                        systemImage: "video.fill"
                    )
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(FurryTailsTheme.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 30)
            .navigationTitle("Go Live")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    // MARK: - Profile Image

    @ViewBuilder
    private func profileImage(
        url: String?,
        size: CGFloat
    ) -> some View {

        if let url,
           let imageURL = URL(string: url) {

            AsyncImage(url: imageURL) { phase in

                switch phase {

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                default:
                    defaultProfileImage
                }

            }
            .frame(width: size, height: size)
            .clipShape(Circle())

        } else {

            defaultProfileImage
                .frame(width: size, height: size)
        }
    }

    private var defaultProfileImage: some View {
        Circle()
            .fill(Color.white.opacity(0.25))
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
            )
    }

    // MARK: - Load Live Photo

    private func loadLivePhoto(
        from item: PhotosPickerItem?
    ) {

        guard let item else {
            return
        }

        item.loadTransferable(
            type: PHLivePhoto.self
        ) { result in

            switch result {

            case .success(let livePhoto):

                DispatchQueue.main.async {
                    self.livePhoto = livePhoto
                }

            case .failure(let error):

                print(
                    "❌ Error loading Live Photo: \(error.localizedDescription)"
                )
            }
        }
    }
}

// MARK: - Live Session Avatar

private struct LiveSessionAvatar: View {

    let session: LiveSession
    let isSelected: Bool
    let isCurrentUser: Bool
    let action: () -> Void

    var body: some View {

        Button(action: action) {

            VStack(spacing: 7) {

                ZStack(alignment: .bottomTrailing) {

                    avatar

                    Circle()
                        .fill(Color.red)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(
                                    Color.white,
                                    lineWidth: 2
                                )
                        )
                }
                .overlay(
                    Circle()
                        .stroke(
                            isSelected
                            ? FurryTailsTheme.orange
                            : Color.clear,
                            lineWidth: 3
                        )
                        .padding(-4)
                )

                Text(
                    isCurrentUser
                    ? "You"
                    : session.hostUsername
                )
                .font(.caption)
                .fontWeight(
                    isSelected
                    ? .bold
                    : .regular
                )
                .foregroundColor(
                    FurryTailsTheme.primaryText
                )
                .lineLimit(1)
                .frame(width: 68)
            }
        }
        .buttonStyle(.plain)
    }

    private var avatar: some View {

        Group {

            if let url = session.hostProfileImageURL,
               let imageURL = URL(string: url) {

                AsyncImage(url: imageURL) { phase in

                    switch phase {

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .padding(2)
                            .background(Color.white)

                    default:
                        defaultAvatar
                    }

                }

            } else {

                defaultAvatar
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(Circle())
    }

    private var defaultAvatar: some View {

        Circle()
            .fill(FurryTailsTheme.orange.opacity(0.2))
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(
                        FurryTailsTheme.orange
                    )
            )
    }
}

// MARK: - Live Photo Player

struct LivePhotoPlayerView: UIViewRepresentable {

    let livePhoto: PHLivePhoto

    func makeUIView(
        context: Context
    ) -> PHLivePhotoView {

        let view = PHLivePhotoView()

        view.livePhoto = livePhoto

        view.startPlayback(
            with: .hint
        )

        return view
    }

    func updateUIView(
        _ uiView: PHLivePhotoView,
        context: Context
    ) {

        uiView.livePhoto = livePhoto
    }
}

// MARK: - Video Capture

struct VideoCaptureView: UIViewControllerRepresentable {

    @Environment(\.presentationMode)
    var presentationMode

    @Binding var videoURL: URL?

    func makeUIViewController(
        context: Context
    ) -> UIImagePickerController {

        let picker = UIImagePickerController()

        picker.sourceType = .camera
        picker.mediaTypes = ["public.movie"]
        picker.cameraCaptureMode = .video
        picker.videoQuality = .typeHigh
        picker.delegate = context.coordinator

        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator:
        NSObject,
        UINavigationControllerDelegate,
        UIImagePickerControllerDelegate {

        let parent: VideoCaptureView

        init(
            _ parent: VideoCaptureView
        ) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info:
                [UIImagePickerController.InfoKey: Any]
        ) {

            // Correct key for captured video.
            if let url =
                info[.mediaURL] as? URL {

                parent.videoURL = url
            }

            parent.presentationMode
                .wrappedValue
                .dismiss()
        }

        func imagePickerControllerDidCancel(
            _ picker: UIImagePickerController
        ) {

            parent.presentationMode
                .wrappedValue
                .dismiss()
        }
    }
}
