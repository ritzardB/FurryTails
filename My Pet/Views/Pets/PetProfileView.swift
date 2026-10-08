import SwiftUI
import FirebaseFirestore

struct PetProfileView: View {

    let pet: Pet

    @State private var currentPet: Pet
    @State private var showEditPet = false
    @State private var isRefreshing = false

    private let db = Firestore.firestore()

    init(pet: Pet) {
        self.pet = pet
        _currentPet = State(initialValue: pet)
    }

    var body: some View {

        ScrollView {

            VStack(spacing: 20) {

                // MARK: - Hero

                heroSection

                // MARK: - Identity

                identitySection

                // MARK: - Personality

                personalitySection

                // MARK: - About

                if let bio = currentPet.bio,
                   !bio.trimmingCharacters(
                       in: .whitespacesAndNewlines
                   ).isEmpty {

                    aboutSection(bio)
                }

                // MARK: - Gallery

                gallerySection
            }
            .padding(.bottom, 30)
        }
        .background(
            FurryTailsTheme.background
        )
        .navigationTitle(currentPet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(
                placement: .navigationBarTrailing
            ) {

                Button {

                    showEditPet = true

                } label: {

                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEditPet) {

            EditPetView(
                pet: currentPet
            ) {

                Task {
                    await refreshPet()
                }
            }
        }
    }

    // MARK: - Refresh Pet

    private func refreshPet() async {

        guard let petId = currentPet.id else {
            return
        }

        isRefreshing = true

        do {

            let document = try await db
                .collection("pets")
                .document(petId)
                .getDocument()

            if document.exists {

                let refreshedPet = try document.data(
                    as: Pet.self
                )

                await MainActor.run {

                    currentPet = refreshedPet
                    isRefreshing = false
                }

                print("🔄 Pet profile refreshed")
                print("🐾 \(refreshedPet.name)")
            }

        } catch {

            print("❌ Failed to refresh pet profile")
            print(error.localizedDescription)

            await MainActor.run {
                isRefreshing = false
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {

        VStack(spacing: 14) {

            petProfileImage

            Text(currentPet.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(
                    FurryTailsTheme.primaryText
                )

            HStack(spacing: 6) {

                Text(currentPet.species)

                if let breed = currentPet.breed,
                   !breed.isEmpty {

                    Text("•")
                    Text(breed)
                }

                if let age = currentPet.age {

                    Text("•")

                    Text(
                        "\(age) \(age == 1 ? "year" : "years")"
                    )
                }
            }
            .font(.subheadline)
            .foregroundColor(
                FurryTailsTheme.secondaryText
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .padding(.horizontal)
    }

    // MARK: - Profile Image

    private var petProfileImage: some View {

        Group {

            if let url = URL(
                string: currentPet.petImageURL
            ),
               !currentPet.petImageURL.isEmpty {

                AsyncImage(url: url) { phase in

                    switch phase {

                    case .empty:

                        ProgressView()
                            .frame(
                                width: 150,
                                height: 150
                            )

                    case .success(let image):

                        image
                            .resizable()
                            .scaledToFill()
                            .padding(4)

                    case .failure:

                        defaultPetImage

                    @unknown default:

                        defaultPetImage
                    }
                }

            } else {

                defaultPetImage
            }
        }
        .frame(width: 150, height: 150)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(
                    FurryTailsTheme.orange,
                    lineWidth: 4
                )
        )
        .shadow(
            color: FurryTailsTheme.orange.opacity(0.20),
            radius: 10,
            y: 5
        )
    }

    private var defaultPetImage: some View {

        ZStack {

            Circle()
                .fill(
                    FurryTailsTheme.orangeSoft
                        .opacity(0.55)
                )

            Image(systemName: "pawprint.fill")
                .font(.system(size: 55))
                .foregroundColor(
                    FurryTailsTheme.orange
                )
        }
    }

    // MARK: - Identity

    private var identitySection: some View {

        profileCard(
            title: "Identity",
            icon: "pawprint.fill"
        ) {

            VStack(spacing: 0) {

                profileRow(
                    title: "Species",
                    value: currentPet.species,
                    icon: "pawprint.fill"
                )

                if let breed = currentPet.breed,
                   !breed.isEmpty {

                    profileRow(
                        title: "Breed",
                        value: breed,
                        icon: "tag.fill"
                    )
                }

                if let sex = currentPet.sex,
                   !sex.isEmpty {

                    profileRow(
                        title: "Sex",
                        value: sex,
                        icon: "person.fill"
                    )
                }

                if let color = currentPet.color,
                   !color.isEmpty {

                    profileRow(
                        title: "Color",
                        value: color,
                        icon: "paintpalette.fill"
                    )
                }

                if let marks = currentPet.distinguishingMarks,
                   !marks.isEmpty {

                    profileRow(
                        title: "Distinguishing Marks",
                        value: marks,
                        icon: "sparkles"
                    )
                }

                if let chip = currentPet.microchipNumber,
                   !chip.isEmpty {

                    profileRow(
                        title: "Microchip #",
                        value: maskedChipNumber(chip),
                        icon: "number"
                    )
                }
            }
        }
    }

    // MARK: - Personality

    private var personalitySection: some View {

        profileCard(
            title: "Personality",
            icon: "heart.fill"
        ) {

            VStack(alignment: .leading, spacing: 16) {

                if let character = currentPet.character,
                   !character.isEmpty {

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        Text("Character")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(
                                FurryTailsTheme.secondaryText
                            )

                        Text(character)
                            .font(.body)
                            .foregroundColor(
                                FurryTailsTheme.primaryText
                            )
                    }
                }

                if let traits = currentPet.traits,
                   !traits.isEmpty {

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        Text("Traits")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(
                                FurryTailsTheme.secondaryText
                            )

                        Text(traits)
                            .font(.body)
                            .foregroundColor(
                                FurryTailsTheme.primaryText
                            )
                    }
                }

                if let characteristics =
                    currentPet.characteristics,
                   !characteristics.isEmpty {

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        Text("Characteristics")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(
                                FurryTailsTheme.secondaryText
                            )

                        Text(characteristics)
                            .font(.body)
                            .foregroundColor(
                                FurryTailsTheme.primaryText
                            )
                    }
                }

                if currentPet.character == nil &&
                    currentPet.traits == nil &&
                    currentPet.characteristics == nil {

                    Text(
                        "No personality information available yet."
                    )
                    .font(.subheadline)
                    .foregroundColor(
                        FurryTailsTheme.secondaryText
                    )
                }
            }
        }
    }

    // MARK: - About

    private func aboutSection(
        _ bio: String
    ) -> some View {

        profileCard(
            title: "About \(currentPet.name)",
            icon: "text.quote"
        ) {

            Text(bio)
                .font(.body)
                .foregroundColor(
                    FurryTailsTheme.primaryText
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
        }
    }

    // MARK: - Gallery

    @ViewBuilder
    private var gallerySection: some View {

        if !currentPet.petGalleryURLs.isEmpty {

            VStack(alignment: .leading, spacing: 12) {

                HStack {

                    Image(systemName: "photo.on.rectangle")
                        .foregroundColor(
                            FurryTailsTheme.orange
                        )

                    Text("Gallery")
                        .font(.headline)
                        .fontWeight(.bold)

                    Spacer()
                }

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ],
                    spacing: 10
                ) {

                    ForEach(
                        currentPet.petGalleryURLs,
                        id: \.self
                    ) { imageURL in

                        if let url = URL(string: imageURL) {

                            AsyncImage(url: url) { phase in

                                switch phase {

                                case .empty:

                                    RoundedRectangle(
                                        cornerRadius: 12
                                    )
                                    .fill(
                                        FurryTailsTheme
                                            .orangeSoft
                                            .opacity(0.25)
                                    )
                                    .frame(height: 160)
                                    .overlay {
                                        ProgressView()
                                    }

                                case .success(let image):

                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(
                                            maxWidth: .infinity,
                                            minHeight: 160,
                                            maxHeight: 160
                                        )
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerRadius: 12
                                            )
                                        )

                                case .failure:

                                    galleryPlaceholder

                                @unknown default:

                                    galleryPlaceholder
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var galleryPlaceholder: some View {

        RoundedRectangle(cornerRadius: 16)
            .fill(
                FurryTailsTheme.orangeSoft
                    .opacity(0.35)
            )
            .frame(
                maxWidth: .infinity,
                minHeight: 180
            )
            .overlay {

                Image(systemName: "photo")
                    .font(.system(size: 32))
                    .foregroundColor(
                        FurryTailsTheme.orange
                    )
            }
    }

    // MARK: - Reusable Card

    private func profileCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack(spacing: 8) {

                Image(systemName: icon)
                    .foregroundColor(
                        FurryTailsTheme.orange
                    )

                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(
                        FurryTailsTheme.primaryText
                    )

                Spacer()
            }

            content()
        }
        .padding(18)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            FurryTailsTheme.cardBackground
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
        .shadow(
            color: .black.opacity(0.05),
            radius: 8,
            y: 3
        )
        .padding(.horizontal)
    }

    // MARK: - Profile Row

    private func profileRow(
        title: String,
        value: String,
        icon: String
    ) -> some View {

        HStack(spacing: 12) {

            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(
                    FurryTailsTheme.orange
                )
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(
                    FurryTailsTheme.secondaryText
                )

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(
                    FurryTailsTheme.primaryText
                )
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 9)
    }

    // MARK: - Microchip Privacy

    private func maskedChipNumber(
        _ chip: String
    ) -> String {

        guard chip.count > 4 else {
            return "••••"
        }

        let suffix = String(chip.suffix(4))

        return "••••••••\(suffix)"
    }
}
