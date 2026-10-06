import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var currentUser: UserModel?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        Task {
            await checkAuthStatus()
        }
    }

    // MARK: - Check Authentication

    func checkAuthStatus() async {

        guard let user = AuthService.currentUser() else {
            return
        }

        do {

            currentUser = try await AuthService.loadUser(
                uid: user.uid
            )

            isAuthenticated = true

        } catch {

            errorMessage = error.localizedDescription

            print(
                "⚠️ Error loading user: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Sign In

    func signIn(
        email: String,
        password: String
    ) async {

        isLoading = true
        defer {
            isLoading = false
        }

        do {

            currentUser = try await AuthService.signIn(
                email: email,
                password: password
            )

            isAuthenticated = true

        } catch {

            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    func signOut() {

        do {

            try AuthService.signOut()

            currentUser = nil
            isAuthenticated = false

        } catch {

            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign Up

    func signUp(
        email: String,
        password: String,
        username: String
    ) async {

        isLoading = true
        defer {
            isLoading = false
        }

        do {

            currentUser = try await AuthService.signUp(
                email: email,
                password: password,
                username: username
            )

            isAuthenticated = true

        } catch {

            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Update User Profile

    func updateUserProfile(
        username: String,
        profileImageData: Data?
    ) async {

        guard var user = currentUser else {
            print("❌ No current user")
            return
        }

        isLoading = true
        defer {
            isLoading = false
        }

        do {

            // Update username
            user.username = username

            // Upload new profile image only if one was selected
            if let imageData = profileImageData {

                guard let uid = user.id else {
                    print("❌ User ID is missing")
                    return
                }

                let storageRef = Storage.storage()
                    .reference()
                    .child("profile_images/\(uid).jpg")

                print("📤 Uploading profile image...")
                print("📁 Storage path: profile_images/\(uid).jpg")

                _ = try await storageRef.putDataAsync(
                    imageData
                )

                print("✅ Profile image uploaded")

                let downloadURL =
                    try await storageRef.downloadURL()

                print("🔗 Profile image URL obtained")

                user.profileImageURL =
                    downloadURL.absoluteString
            }

            // Save updated user to Firestore
            try await AuthService.updateUser(user)

            // Immediately update local state
            currentUser = user

            print("✅ User profile updated successfully")

        } catch {

            errorMessage =
                error.localizedDescription

            print(
                "❌ Failed to update profile: \(error.localizedDescription)"
            )
        }
    }
    
    // MARK: - Google Sign In

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            currentUser = try await AuthService.signInWithGoogle()
            isAuthenticated = true

            print("✅ Google Sign-In successful")
            print("👤 User: \(currentUser?.username ?? "Unknown")")
            print("📧 Email: \(currentUser?.email ?? "Unknown")")

        } catch {
            errorMessage = error.localizedDescription

            print("❌ Google Sign-In failed")
            print("❌ Error: \(error.localizedDescription)")
        }
    }
}
