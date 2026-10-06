//
//  LivePhotoView.swift
//  My Pets
//
//  Created by Richard Balabarcon on 13/10/2025.
//

import SwiftUI
import PhotosUI
import AVKit
import Photos

struct LivePhotoView: View {
    @State private var livePhoto: PHLivePhoto?
    @State private var recordedVideoURL: URL?
    @State private var isRecording = false
    @State private var showVideoPlayer = false
    @State private var showPicker = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var showFloatingButtons = true

    var body: some View {
        VStack(spacing: 20) {
            Text("Live Moment")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)

            ZStack(alignment: .bottomTrailing) {
                // --- Main content (Live Photo or Video)
                if let livePhoto = livePhoto {
                    LivePhotoPlayerView(livePhoto: livePhoto)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(16)
                        .shadow(radius: 6)
                        .onAppear { autoHideControls() }
                } else if let videoURL = recordedVideoURL {
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(16)
                        .shadow(radius: 6)
                        .onAppear { autoHideControls() }
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(Text("No Live Content Yet").foregroundColor(.gray))
                }

                // --- Floating Buttons
                if showFloatingButtons {
                    VStack(spacing: 12) {
                        // Live Photo picker
                        Button(action: { showPicker.toggle() }) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 20, weight: .bold))
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }

                        // Record video
                        Button(action: { showVideoPlayer.toggle() }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20, weight: .bold))
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                    }
                    .padding()
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showFloatingButtons)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showPicker) {
            PhotosPicker(
                selection: $pickerItem,
                matching: .livePhotos,
                photoLibrary: .shared()
            ) {
                Text("Select Live Photo")
            }
            .onChange(of: pickerItem) { oldItem, newItem in
                loadLivePhoto(from: newItem)
            }
        }
        .sheet(isPresented: $showVideoPlayer) {
            VideoCaptureView(videoURL: $recordedVideoURL)
        }
        // Tap anywhere to toggle floating buttons
        .onTapGesture {
            withAnimation {
                showFloatingButtons.toggle()
            }
        }
    }

    // MARK: - Hide buttons automatically after a few seconds
    private func autoHideControls() {
        withAnimation(.easeInOut(duration: 0.5).delay(3)) {
            showFloatingButtons = false
        }
    }

    // MARK: - Load selected Live Photo
    private func loadLivePhoto(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        item.loadTransferable(type: PHLivePhoto.self) { result in
            switch result {
            case .success(let livePhoto):
                self.livePhoto = livePhoto
            case .failure(let error):
                print("Error loading Live Photo: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Live Photo Player (UIKit)
struct LivePhotoPlayerView: UIViewRepresentable {
    let livePhoto: PHLivePhoto

    func makeUIView(context: Context) -> PHLivePhotoView {
        let view = PHLivePhotoView()
        view.livePhoto = livePhoto
        view.startPlayback(with: .hint)
        return view
    }

    func updateUIView(_ uiView: PHLivePhotoView, context: Context) {
        uiView.livePhoto = livePhoto
    }
}

// MARK: - Video Capture using UIImagePickerController
struct VideoCaptureView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var videoURL: URL?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.movie"]
        picker.cameraCaptureMode = .video
        picker.videoQuality = .typeHigh
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: VideoCaptureView

        init(_ parent: VideoCaptureView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let url = info[.imageURL] as? URL {
                parent.videoURL = url
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
