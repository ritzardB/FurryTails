//
//  MainTabView.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import SwiftUI

struct MainTabView: View {
    @Binding var deepLinkedPostId: String?

    var body: some View {
        TabView {
            FeedView(deepLinkedPostId: $deepLinkedPostId)
                .tabItem {
                    Label("Feed", systemImage: "house.fill")
                }

            MyPetsView()
                .tabItem {
                    Label("My Pets", systemImage: "pawprint.fill")
                }

            AddPostView()
                .tabItem {
                    Label("Post", systemImage: "plus.app.fill")
                }

            LivePhotoView()
                .tabItem {
                    Label("Live", systemImage: "livephoto")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .accentColor(.blue)
    }
}
