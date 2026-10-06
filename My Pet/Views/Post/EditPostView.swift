//
//  EditPostView.swift
//  My Pet
//
//  Created by Richard Balabarcon on 17/10/2025.
//

import SwiftUI


struct EditPostView: View {
    var post: Post
    @State private var caption: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Post")
                .font(.title2)
                .bold()

            TextField("Edit caption...", text: $caption)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Save Changes") {
                // TODO: Update Firebase document
                print("Updated post caption: \(caption)")
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .onAppear { caption = post.caption }
    }
}
