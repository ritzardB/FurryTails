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

    @State private var showHero = false
    
    // Deep-Link stats
    @State private var deepLinkedPostId: String?

    // MARK: - Firebase Initialization

    init() {
        FirebaseApp.configure()

        let db = Firestore.firestore()

        db.collection("test").getDocuments { snapshot, error in

            if let error = error {
                print(
                    "🔥 Firestore test failed:",
                    error.localizedDescription
                )
            } else {
                print(
                    "✅ Firestore connected: \(snapshot?.documents.count ?? 0) documents found"
                )
            }
        }
    }

    // MARK: - App Body

    var body: some Scene {

        WindowGroup {

            Group {

                if !authVM.isAuthenticated {

                    // MARK: - Not Authenticated

                    LoginView()
                        .environmentObject(authVM)

                } else if showHero {

                    // MARK: - Post Login Hero

                    HeroView(
                        onFinished: {
                            withAnimation(.easeInOut) {
                                showHero = false
                            }
                        }
                    )
                    .environmentObject(authVM)

                } else {

                    // MARK: - Main Application

                    MainTabView(
                        deepLinkedPostId: $deepLinkedPostId
                    )
                    .environmentObject(authVM)
                }
            }

            // Detect successful authentication.
            .onChange(
                of: authVM.isAuthenticated
            ) { _, authenticated in

                if authenticated {
                    withAnimation(.easeInOut) {
                        showHero = true
                    }
                } else {
                    showHero = false
                }
            }
        }
    }
}
