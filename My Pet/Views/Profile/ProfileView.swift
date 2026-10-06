//
//  ProfileView.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {

    // If user is supplied, show that user's profile.
    // If nil, show the currently authenticated user's profile.
    var user: UserModel? = nil

    @EnvironmentObject var authVM: AuthViewModel

    @State private var showEditProfile = false

    // MARK: - Displayed User

    private var displayedUser: UserModel? {
        user ?? authVM.currentUser
    }

    private var isOwnProfile: Bool {
        guard let displayedUserID = displayedUser?.id,
              let currentUserID = authVM.currentUser?.id else {
            return false
        }

        return displayedUserID == currentUserID
    }

    // MARK: - Body

    var body: some View {

        NavigationView {

            ScrollView {

                VStack(spacing: 0) {

                    if let profileUser = displayedUser {

                        // MARK: - Profile Header

                        VStack(spacing: 12) {

                            // Profile Image
                            AsyncImage(
                                url: URL(
                                    string: profileUser.profileImageURL ?? ""
                                )
                            ) { phase in

                                switch phase {

                                case .success(let image):

                                    image
                                        .resizable()
                                        .scaledToFill()

                                case .failure(_):

                                    Image(
                                        systemName: "person.circle.fill"
                                    )
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(
                                        .gray.opacity(0.4)
                                    )

                                case .empty:

                                    Image(
                                        systemName: "person.circle.fill"
                                    )
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(
                                        .gray.opacity(0.4)
                                    )

                                @unknown default:

                                    Image(
                                        systemName: "person.circle.fill"
                                    )
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(
                                        .gray.opacity(0.4)
                                    )
                                }
                            }
                            .frame(width: 110, height: 110)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        Color.gray.opacity(0.15),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(
                                color: .black.opacity(0.15),
                                radius: 5
                            )

                            // Username
                            Text(profileUser.username)
                                .font(.title2)
                                .fontWeight(.semibold)

                            // Email
                            Text(profileUser.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            // Bio
                            if let bio = profileUser.bio,
                               !bio.isEmpty {

                                Text(bio)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 30)
                                    .padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 25)
                        .padding(.bottom, 20)

                        Divider()
                            .padding(.horizontal)
                            .padding(.bottom, 20)

                        // MARK: - Pets

                        VStack(alignment: .leading, spacing: 12) {

                            HStack {

                                Text(
                                    isOwnProfile
                                    ? "Your Pets"
                                    : "\(profileUser.username)’s Pets"
                                )
                                .font(.headline)

                                Spacer()
                            }
                            .padding(.horizontal)

                            PetGalleryView(
                                ownerId: profileUser.id ?? ""
                            )
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 220,
                                maxHeight: 400
                            )
                        }

                        Spacer()
                            .frame(height: 40)

                    } else {

                        // MARK: - Loading

                        VStack(spacing: 15) {

                            ProgressView()

                            Text("Loading profile...")
                                .foregroundColor(.secondary)
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 300
                        )
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle(
                displayedUser?.username ?? "Profile"
            )
            .navigationBarTitleDisplayMode(.inline)

            // MARK: - Profile Menu

            .toolbar {

                if isOwnProfile {

                    ToolbarItem(
                        placement: .navigationBarTrailing
                    ) {

                        Menu {

                            // Edit Profile
                            Button {

                                showEditProfile = true

                            } label: {

                                Label(
                                    "Edit Profile",
                                    systemImage: "pencil"
                                )
                            }

                            // Sign Out
                            Button(
                                role: .destructive
                            ) {

                                authVM.signOut()

                            } label: {

                                Label(
                                    "Sign Out",
                                    systemImage:
                                        "rectangle.portrait.and.arrow.right"
                                )
                            }

                        } label: {

                            Image(
                                systemName: "ellipsis.circle"
                            )
                            .font(.system(size: 24))
                        }
                    }
                }
            }

            // MARK: - Edit Profile

            .sheet(
                isPresented: $showEditProfile
            ) {

                NavigationView {

                    EditProfileView()
                        .environmentObject(authVM)
                }
            }
        }
    }
}
