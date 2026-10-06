//
//  My_PetsApp.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import SwiftUI
import Firebase
import FirebaseCore
import FirebaseFirestore

@main
struct my_Petsapp: App {
    @StateObject private var authVM = AuthViewModel()

    // Firebase initialization
    init() {
        FirebaseApp.configure()
        let db = Firestore.firestore()
        db.collection("test").getDocuments { snapshot, error in
            if let error = error {
                print("🔥 Firestore test failed:", error.localizedDescription)
            } else {
                print("✅ Firestore connected: \(snapshot?.documents.count ?? 0) documents found")
            }
        }
    }


    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isAuthenticated {
                    // your main app (once logged in)
                    MainTabView()
                        .environmentObject(authVM)
                } else {
                    // show login/register flow
                    LoginView()
                        .environmentObject(authVM)
                }
            }
        }
    }
}
