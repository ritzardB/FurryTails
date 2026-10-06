//
//  EditProfileView.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authVM: AuthViewModel

    @State private var username: String = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isSaving = false

    var body: some View {

        VStack(spacing: 20) {

            // MARK: - Profile Image

            PhotosPicker(
                selection: $selectedImage,
                matching: .images
            ) {

                if let profileImage {

                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: 110,
                            height: 110
                        )
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    Color.blue.opacity(0.3),
                                    lineWidth: 2
                                )
                        )

                } else {

                    profilePlaceholder
                }
            }
            .onChange(of: selectedImage) { _, newItem in

                guard let newItem else {
                    return
                }

                Task { @MainActor in

                    do {

                        if let data = try await newItem.loadTransferable(
                            type: Data.self
                        ),
                        let image = UIImage(data: data) {

                            profileImage = image

                            print("📸 Profile image selected")
                            print("📦 Image size: \(data.count) bytes")
                        }

                    } catch {

                        print(
                            "❌ Failed to load profile image: \(error.localizedDescription)"
                        )
                    }
                }
            }

            // MARK: - Username

            TextField(
                "Username",
                text: $username
            )
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)

            // MARK: - Save Button

            Button {

                saveProfile()

            } label: {

                Group {

                    if isSaving {

                        ProgressView()
                            .tint(.white)

                    } else {

                        Text("Save Changes")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    isSaving
                    ? Color.gray
                    : Color.blue
                )
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .disabled(
                isSaving ||
                username.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
            )

            Spacer()
        }
        .padding(.top, 20)
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            username = authVM.currentUser?.username ?? ""
        }
    }

    // MARK: - Save Profile

    private func saveProfile() {

        let trimmedUsername = username
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmedUsername.isEmpty else {
            print("❌ Username cannot be empty")
            return
        }

        isSaving = true

        Task { @MainActor in

            let imageData = profileImage?.jpegData(
                compressionQuality: 0.85
            )

            print("💾 Saving profile...")
            print("👤 Username: \(trimmedUsername)")

            if let imageData {
                print(
                    "📸 New profile image: \(imageData.count) bytes"
                )
            } else {
                print("📸 No new profile image selected")
            }

            await authVM.updateUserProfile(
                username: trimmedUsername,
                profileImageData: imageData
            )

            isSaving = false

            if authVM.errorMessage == nil {

                print("✅ Profile saved successfully")

                dismiss()
            } else {

                print(
                    "❌ Profile save failed: \(authVM.errorMessage ?? "Unknown error")"
                )
            }
        }
    }

    // MARK: - Profile Placeholder

    private var profilePlaceholder: some View {

        Group {

            if let imageURL = authVM.currentUser?.profileImageURL,
               let url = URL(string: imageURL) {

                AsyncImage(url: url) { phase in

                    switch phase {

                    case .success(let image):

                        image
                            .resizable()
                            .scaledToFill()

                    case .failure(_):

                        placeholderIcon

                    case .empty:

                        ProgressView()

                    @unknown default:

                        placeholderIcon
                    }
                }

            } else {

                placeholderIcon
            }
        }
        .frame(
            width: 110,
            height: 110
        )
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Placeholder Icon

    private var placeholderIcon: some View {

        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFill()
            .foregroundColor(
                .gray.opacity(0.4)
            )
    }
}
