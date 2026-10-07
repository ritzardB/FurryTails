//
//  FeedView.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import SwiftUI
import FirebaseFirestore

struct FeedView: View {
    
    @Binding var deepLinkedPostId: String?

    @StateObject private var viewModel = FeedUploadViewModel()
    @State private var isLoading = true

    // MARK: - Navigation State

    @State private var showAddPost = false
    @State private var showSearch = false
    @State private var showMenu = false
    
    init(deepLinkedPostId: Binding<String?> = .constant(nil)) {
           self._deepLinkedPostId = deepLinkedPostId
       }


    var body: some View {

        NavigationView {

            ZStack {

                FurryTailsTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {

                    if isLoading {

                        ProgressView("Loading feed…")
                            .padding(.top, 100)

                    } else {

                        VStack(
                            alignment: .leading,
                            spacing: 20
                        ) {

                            // MARK: - Horizontal User List

                            ScrollView(
                                .horizontal,
                                showsIndicators: false
                            ) {

                                HStack(spacing: 16) {

                                    ForEach(
                                        viewModel.users
                                    ) { user in

                                        VStack(spacing: 6) {

                                            AsyncImage(
                                                url: URL(
                                                    string:
                                                        user.profileImageURL ?? ""
                                                )
                                            ) { image in

                                                image
                                                    .resizable()
                                                    .scaledToFill()

                                            } placeholder: {

                                                Image(
                                                    systemName:
                                                        "person.circle.fill"
                                                )
                                                .resizable()
                                                .foregroundColor(
                                                    .gray.opacity(0.4)
                                                )
                                            }
                                            .frame(
                                                width: 50,
                                                height: 50
                                            )
                                            .clipShape(
                                                RoundedRectangle(
                                                    cornerRadius: 12
                                                )
                                            )
                                            .shadow(radius: 3)

                                            Text(user.username)
                                                .font(.caption)
                                                .lineLimit(1)
                                                .frame(width: 60)
                                                .foregroundColor(
                                                    FurryTailsTheme.primaryText
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 8)
                            }

                            // MARK: - Feed Posts

                            LazyVStack(spacing: 20) {

                                ForEach(
                                    viewModel.feedItems
                                ) { item in

                                    switch item.type {

                                    case .post:

                                        if let post = item.post {

                                            PostCardView(
                                                post: post,
                                                user: item.user
                                            )
                                        }

                                    case .pet:

                                        if let pet = item.pet {

                                            PetProfileView(
                                                pet: pet
                                            )
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }

                // MARK: - Side Menu

                if showMenu {

                    Color.black
                        .opacity(0.25)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                showMenu = false
                            }
                        }

                    HStack {

                        VStack(
                            alignment: .leading,
                            spacing: 0
                        ) {

                            // Menu Header

                            VStack(
                                alignment: .leading,
                                spacing: 8
                            ) {

                                Text("FurryTails")
                                    .font(
                                        .system(
                                            size: 28,
                                            weight: .bold,
                                            design: .rounded
                                        )
                                    )
                                    .foregroundColor(
                                        FurryTailsTheme.brown
                                    )

                                Text("Where every pet has a story 🐾")
                                    .font(.caption)
                                    .foregroundColor(
                                        FurryTailsTheme.secondaryText
                                    )
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 60)
                            .padding(.bottom, 25)

                            Divider()

                            // Menu Items

                            menuItem(
                                title: "Home",
                                icon: "house.fill"
                            ) {
                                closeMenu()
                            }

                            menuItem(
                                title: "My Pets",
                                icon: "pawprint.fill"
                            ) {
                                closeMenu()
                            }

                            menuItem(
                                title: "Notifications",
                                icon: "bell.fill"
                            ) {
                                closeMenu()
                            }

                            menuItem(
                                title: "Messages",
                                icon: "message.fill"
                            ) {
                                closeMenu()
                            }

                            menuItem(
                                title: "Settings",
                                icon: "gearshape.fill"
                            ) {
                                closeMenu()
                            }

                            Spacer()

                            Divider()
                            
                            menuItem(
                                title: "Vet Services",
                                icon: "stethoscope.circle.fill"
                            ) {
                                closeMenu()
                            }
                            
                            Spacer()
                            
                            Divider()
                            
                            

                            menuItem(
                                title: "Sign Out",
                                icon: "rectangle.portrait.and.arrow.right"
                            ) {
                                closeMenu()
                            }
                            .foregroundColor(.red)

                            Spacer()
                                .frame(height: 25)
                        }
                        .frame(
                            width: 290
                        )
                        .frame(
                            maxHeight: .infinity
                        )
                        .background(
                            FurryTailsTheme.cardBackground
                        )
                        .shadow(
                            color: .black.opacity(0.2),
                            radius: 12,
                            x: 5,
                            y: 0
                        )

                        Spacer()
                    }
                    .transition(
                        .move(edge: .leading)
                    )
                }
            }

            // MARK: - Custom Navigation Bar

            .safeAreaInset(edge: .top) {

                HStack {

                    // Hamburger Menu

                    Button {

                        withAnimation(.easeInOut) {
                            showMenu.toggle()
                        }

                    } label: {

                        Image(
                            systemName: "line.3.horizontal"
                        )
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(
                            FurryTailsTheme.brown
                        )
                        .frame(
                            width: 42,
                            height: 42
                        )
                    }

                    Spacer()

                    // FurryTails Logo / Title

                    HStack(spacing: 5) {

                        Text("FurryTails")
                            .font(
                                .system(
                                    size: 20,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )

                        Text("🐾")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(
                        FurryTailsTheme.brown
                    )

                    Spacer()

                    // Add Post

                    Button {

                        showAddPost = true

                    } label: {

                        Image(
                            systemName: "plus"
                        )
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(
                            FurryTailsTheme.brown
                        )
                        .frame(
                            width: 38,
                            height: 42
                        )
                    }

                    // Search

                    Button {

                        showSearch = true

                    } label: {

                        Image(
                            systemName: "magnifyingglass"
                        )
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(
                            FurryTailsTheme.brown
                        )
                        .frame(
                            width: 38,
                            height: 42
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    FurryTailsTheme.cardBackground
                        .shadow(
                            color: .black.opacity(0.08),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                )
            }

            // MARK: - Initial Load

            .task {

                await viewModel.fetchPosts()

                isLoading = false
            }

            // MARK: - Pull To Refresh

            .refreshable {

                await viewModel.refreshFeed()
            }

            // MARK: - New Post

            .onReceive(
                NotificationCenter.default.publisher(
                    for: .postCreated
                )
            ) { _ in

                Task {

                    print("📣 Post created — refreshing feed")

                    await viewModel.refreshFeed()
                }
            }

            // MARK: - Add Post

            .sheet(
                isPresented: $showAddPost
            ) {

                AddPostView()
            }

            // MARK: - Search

            .sheet(
                isPresented: $showSearch
            ) {

                NavigationView {

                    VStack(spacing: 20) {

                        Image(
                            systemName: "magnifyingglass"
                        )
                        .font(.system(size: 45))
                        .foregroundColor(
                            FurryTailsTheme.orange
                        )

                        Text("Search")
                            .font(
                                .title2.bold()
                            )

                        Text(
                            "Search functionality is coming soon."
                        )
                        .foregroundColor(.secondary)
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .background(
                        FurryTailsTheme.background
                    )
                    .navigationTitle("Search")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Menu Item

    @ViewBuilder
    private func menuItem(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {

        Button {

            action()

        } label: {

            HStack(spacing: 16) {

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .frame(width: 25)

                Text(title)
                    .font(
                        .system(
                            size: 16,
                            weight: .medium
                        )
                    )

                Spacer()
            }
            .foregroundColor(
                FurryTailsTheme.primaryText
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
        }
    }

    // MARK: - Close Menu

    private func closeMenu() {

        withAnimation(.easeInOut) {
            showMenu = false
        }
    }
}

#Preview {

    FeedView()
}
