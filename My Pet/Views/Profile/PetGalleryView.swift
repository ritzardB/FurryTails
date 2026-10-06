import SwiftUI
import FirebaseFirestore

struct PetGalleryView: View {
    let ownerId: String

    @State private var petImages: [String] = []
    @State private var isLoading = true

    private let db = Firestore.firestore()

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading pets...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if petImages.isEmpty {
                Text("No pets yet. Add your first pet!")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 8
                ) {
                    ForEach(petImages, id: \.self) { imageURL in
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 150)

                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 150)
                                    .clipped()
                                    .cornerRadius(10)

                            case .failure:
                                Image(systemName: "pawprint.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(40)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 150)
                                    .foregroundColor(.gray.opacity(0.5))

                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .task {
            await fetchPets()
        }
    }

    private func fetchPets() async {
        guard !ownerId.isEmpty else {
            print("❌ PetGalleryView: ownerId is empty")
            isLoading = false
            return
        }

        print("🐾 PetGalleryView fetching pets for: \(ownerId)")

        do {
            let snapshot = try await db
                .collection("pets")
                .whereField("ownerId", isEqualTo: ownerId)
                .getDocuments()

            var images: [String] = []

            for document in snapshot.documents {
                let data = document.data()

                print("🐾 Found pet document: \(document.documentID)")
                print("📄 Pet data: \(data)")

                if let imageURL = data["petImageURL"] as? String,
                   !imageURL.isEmpty {
                    images.append(imageURL)
                }
            }

            await MainActor.run {
                petImages = images
                isLoading = false
            }

            print("🐾 PetGalleryView loaded \(images.count) pet images")

        } catch {
            print("❌ PetGalleryView failed to fetch pets:")
            print("❌ \(error.localizedDescription)")

            await MainActor.run {
                isLoading = false
            }
        }
    }
}
