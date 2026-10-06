//
//  AuthServices.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import GoogleSignIn
import UIKit
import FirebaseCore

struct AuthService {

    private static let auth = Auth.auth()
    private static let db = Firestore.firestore()
    private static let usersCollection = db.collection("users")

    // MARK: - Email / Password Sign Up

    static func signUp(
        email: String,
        password: String,
        username: String
    ) async throws -> UserModel {

        let result = try await auth.createUser(
            withEmail: email,
            password: password
        )

        let uid = result.user.uid

        let newUser = UserModel(
            id: uid,
            username: username,
            email: result.user.email ?? "",
            profileImageURL: nil,
            bio: nil,
            pets: [],
            followers: [],
            following: []
        )

        let userRef = usersCollection.document(uid)

        let userData = try Firestore.Encoder().encode(newUser)

        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in

            userRef.setData(userData) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }

        print("✅ Successfully signed up user: \(username)")

        return newUser
    }

    // MARK: - Email / Password Sign In

    static func signIn(
        email: String,
        password: String
    ) async throws -> UserModel {

        let result = try await auth.signIn(
            withEmail: email,
            password: password
        )

        return try await loadUser(uid: result.user.uid)
    }

    // MARK: - Google Sign In

    static func signInWithGoogle() async throws -> UserModel {

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(
                domain: "AuthService",
                code: 1001,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Firebase client ID is missing. Check GoogleService-Info.plist."
                ]
            )
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let presentingViewController = await MainActor.run(
            body: {
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first(where: { $0.isKeyWindow })?
                    .rootViewController
            }
        ) else {
            throw NSError(
                domain: "AuthService",
                code: 1002,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Unable to find the current window."
                ]
            )
        }

        let signInResult = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController
        )

        guard let idToken = signInResult.user.idToken?.tokenString else {
            throw NSError(
                domain: "AuthService",
                code: 1003,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Google ID token is missing."
                ]
            )
        }

        let accessToken = signInResult.user.accessToken.tokenString

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )

        let authResult = try await auth.signIn(
            with: credential
        )

        let firebaseUser = authResult.user
        let uid = firebaseUser.uid

        // Check whether a FurryTails user document already exists.
        let userDocument = try await usersCollection
            .document(uid)
            .getDocument()

        if userDocument.exists {
            print("✅ Existing Google user found: \(uid)")

            return try await loadUser(uid: uid)
        }

        // First Google login — create the FurryTails user.
        let username: String = {

            if let displayName = firebaseUser.displayName,
               !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return displayName
            }

            if let email = firebaseUser.email,
               let name = email.split(separator: "@").first {
                return String(name)
            }

            return "FurryTails User"
        }()

        let profileImageURL = firebaseUser.photoURL?.absoluteString

        let newUser = UserModel(
            id: uid,
            username: username,
            email: firebaseUser.email ?? "",
            profileImageURL: profileImageURL,
            bio: nil,
            pets: [],
            followers: [],
            following: []
        )

        try await saveUser(
            newUser,
            uid: uid
        )

        print("✅ New Google user created: \(username)")
        print("🆔 Firebase UID: \(uid)")

        return newUser
    }

    // MARK: - Load User

    static func loadUser(uid: String) async throws -> UserModel {

        let doc = try await db
            .collection("users")
            .document(uid)
            .getDocument()

        guard let user = try? doc.data(as: UserModel.self) else {
            throw NSError(
                domain: "UserService",
                code: 404,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "User not found"
                ]
            )
        }

        return user
    }

    // MARK: - Update User Profile

    static func updateUser(
        _ user: UserModel
    ) async throws {

        guard let uid = user.id ?? Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "AuthService",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "No user ID found"
                ]
            )
        }

        let data: [String: Any] = [
            "username": user.username,
            "email": user.email,
            "profileImageURL": user.profileImageURL ?? "",
            "updatedAt": Timestamp()
        ]

        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in

            usersCollection
                .document(uid)
                .updateData(data) { error in

                    if let error {
                        continuation.resume(
                            throwing: error
                        )
                    } else {
                        continuation.resume(
                            returning: ()
                        )
                    }
                }
        }
    }

    // MARK: - Sign Out

    static func signOut() throws {

        try auth.signOut()

        // Also sign out from Google.
        GIDSignIn.sharedInstance.signOut()
    }

    // MARK: - Current Firebase User

    static func currentUser() -> FirebaseAuth.User? {
        auth.currentUser
    }

    // MARK: - Save User

    private static func saveUser(
        _ user: UserModel,
        uid: String
    ) async throws {

        let document = usersCollection.document(uid)

        let data = try Firestore.Encoder().encode(user)

        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in

            document.setData(data) { error in

                if let error {
                    continuation.resume(
                        throwing: error
                    )
                } else {
                    continuation.resume(
                        returning: ()
                    )
                }
            }
        }
    }
}
