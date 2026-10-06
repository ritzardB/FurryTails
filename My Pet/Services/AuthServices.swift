//
//  AuthServices.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreCombineSwift


struct AuthService {
    private static let auth = Auth.auth()
    private static let db = Firestore.firestore()
    private static let usersCollection = db.collection("users")
    
    
    static func signUp(email: String, password: String, username: String) async throws -> UserModel {
        let result = try await auth.createUser(withEmail: email, password: password)
        let uid = result.user.uid // ✅ capture the UID from Firebase Auth

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

    
    static func signIn(email: String, password: String) async throws -> UserModel {
        let result = try await auth.signIn(withEmail: email, password: password)
        return try await loadUser(uid: result.user.uid)
    }
    
    static func loadUser(uid: String) async throws -> UserModel {
        let doc = try await db.collection("users").document(uid).getDocument()
        guard let user = try? doc.data(as: UserModel.self) else {
            throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        return user
    }
    
    /// 🧑‍💻 Update user profile info in Firestore
    static func updateUser(_ user: UserModel) async throws {
        guard let uid = user.id ?? Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])
        }
        
        // Convert user model to dictionary
        let data: [String: Any] = [
            "username": user.username,
            "email": user.email,
            "profileImageURL": user.profileImageURL ?? "",
            "updatedAt": Timestamp()
        ]
        
        // Write to Firestore
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in

            usersCollection.document(uid).updateData(data) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    static func signOut() throws {
        try auth.signOut()
    }
    
    static func currentUser() -> FirebaseAuth.User? {
        auth.currentUser
    }
    
    
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
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}





