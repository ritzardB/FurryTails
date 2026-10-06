//
//  MainTabView.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            FeedView()
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
        .accentColor(.blue) // You can change this color
    }
}
