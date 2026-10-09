import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct PetProfileView: View {

    let pet: Pet

    @State private var currentPet: Pet
    @State private var showEditPet = false
    @State private var isRefreshing = false

    // Gallery viewer
    @State private var selectedGalleryItem: GalleryViewerItem?
    @State private var selectedGalleryIndex = 0
    
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
                
                // MARK: - Pet Care Hub
                petCareHubSection  // New section goes here

                if let bio = currentPet.bio, !bio.isEmpty {
                    aboutSection(bio)
                }

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
                .ignoresSafeArea()
        )
        .navigationTitle(currentPet.name)
        .navigationBarTitleDisplayMode(.inline)

        // MARK: - Toolbar

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

        // MARK: - Edit Pet

        .sheet(
            isPresented: $showEditPet
        ) {

            EditPetView(
                pet: currentPet
            ) {

                showEditPet = false

                Task {

                    try? await Task.sleep(
                        nanoseconds: 300_000_000
                    )

                    await refreshPet()
                }
            }
        }
        
        // MARK: - Gallery Viewer

        
        .fullScreenCover(item: $selectedGalleryItem) { item in
            GalleryPhotoViewer(
                imageURL: item.url,
                onAddPhotos: { imageDataArray in
                    await addPhotosToGallery(imageDataArray)
                },
                onDeletePhoto: { imageURL in
                    try await deletePhotoFromGallery(imageURL)
                }
            )
        }
    }
    
    private var petCareHubSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Pet Care Hub")
                .font(.title3.bold())

            Text("Keep track of your pet's health, appointments, and daily care.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                NavigationLink {
                    VetRecordsView(pet: currentPet)
                } label: {
                    petCareRow(
                        title: "Health Records",
                        subtitle: "Medical history, vaccinations and medications",
                        systemImage: "heart.text.clipboard"
                    )
                }

                Divider()

                NavigationLink {
                    VetRecordsView(pet: currentPet)
                } label: {
                    petCareRow(
                        title: "Vet Appointments",
                        subtitle: "Upcoming visits and appointment history",
                        systemImage: "calendar"
                    )
                }

                Divider()

                NavigationLink {
                    VetRecordsView(pet: currentPet)
                } label: {
                    petCareRow(
                        title: "Food & Nutrition",
                        subtitle: "Food preferences and feeding schedules",
                        systemImage: "fork.knife"
                    )
                }

                Divider()

                NavigationLink {
                    VetRecordsView(pet: currentPet)
                } label: {
                    petCareRow(
                        title: "Care Reminders",
                        subtitle: "Vaccinations, medication and routine care",
                        systemImage: "bell.badge"
                    )
                }
            }
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .padding(.horizontal)
    }

    private func petCareRow(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

}

// MARK: - Refresh Pet

extension PetProfileView {

    private func refreshPet() async {

        guard let petId = currentPet.id else {

            print(
                "❌ Cannot refresh pet: missing pet ID"
            )

            return
        }

        await MainActor.run {

            isRefreshing = true
        }

        do {

            let document = try await db
                .collection("pets")
                .document(petId)
                .getDocument()

            guard document.exists else {

                print(
                    "❌ Pet document does not exist: \(petId)"
                )

                await MainActor.run {

                    isRefreshing = false
                }

                return
            }

            let refreshedPet = try document.data(
                as: Pet.self
            )

            print(
                "🔄 Pet profile refreshed"
            )

            print(
                "🐾 \(refreshedPet.name)"
            )

            print(
                "📸 Gallery URLs: \(refreshedPet.petGalleryURLs.count)"
            )

            for url in refreshedPet.petGalleryURLs {

                print(
                    "📸 \(url)"
                )
            }

            await MainActor.run {

                currentPet = refreshedPet
                isRefreshing = false
            }

        } catch {

            print(
                "❌ Failed to refresh pet profile"
            )

            print(
                "❌ \(error.localizedDescription)"
            )

            await MainActor.run {

                isRefreshing = false
            }
        }
    }
    
    // DELETE photo from Gallery Function
    
    
    private func deletePhotoFromGallery(_ imageURL: URL) async throws {
        guard let petId = currentPet.id else {
            throw NSError(
                domain: "PetGallery",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Pet ID is missing."
                ]
            )
        }

        let photoURL = imageURL.absoluteString
        let db = Firestore.firestore()

        // Remove the photo URL from the existing Firestore gallery.
        try await db.collection("pets")
            .document(petId)
            .updateData([
                "petGalleryURLs": FieldValue.arrayRemove([photoURL]),
                "updatedAt": Timestamp()
            ])

        // Refresh the profile so the carousel no longer shows the photo.
        await refreshPet()

        // Delete the corresponding file from Firebase Storage.
        do {
            let storageRef = Storage.storage()
                .reference(forURL: photoURL)

            try await storageRef.delete()
            print("✅ Gallery photo deleted from Storage: \(photoURL)")
        } catch {
            // The photo has already been removed from Firestore.
            // Log the cleanup failure so it can be investigated.
            print("⚠️ Photo removed from gallery, but Storage cleanup failed:")
            print(error.localizedDescription)
        }
    }

    // ADD Photo to Gallery
    
    private func addPhotosToGallery(
        _ imageDataArray: [Data]
    ) async {

        guard let petId = currentPet.id else {
            print("❌ Cannot add gallery photos: missing pet ID")
            return
        }

        guard !imageDataArray.isEmpty else {
            return
        }

        await MainActor.run {
            isRefreshing = true
        }

        let storage = Storage.storage()

        var newGalleryURLs = currentPet.petGalleryURLs

        do {

            for imageData in imageDataArray {

                let fileName = "\(UUID().uuidString).jpg"

                let galleryRef = storage
                    .reference()
                    .child(
                        "pet_images/\(petId)/gallery/\(fileName)"
                    )

                _ = try await galleryRef.putDataAsync(
                    imageData,
                    metadata: nil
                )

                let downloadURL =
                    try await galleryRef.downloadURL()

                newGalleryURLs.append(
                    downloadURL.absoluteString
                )

                print("📸 Gallery image uploaded:")
                print(downloadURL.absoluteString)
            }

            // Remove duplicates just in case
            newGalleryURLs = Array(
                Set(newGalleryURLs)
            )

            // Preserve the existing gallery order as much as possible
            let updatedGalleryURLs =
                currentPet.petGalleryURLs +
                newGalleryURLs.filter {
                    !currentPet.petGalleryURLs.contains($0)
                }

            try await Firestore.firestore()
                .collection("pets")
                .document(petId)
                .updateData([
                    "petGalleryURLs": updatedGalleryURLs,
                    "updatedAt": Timestamp()
                ])

            print("✅ Gallery updated successfully")
            print("📸 Total gallery photos: \(updatedGalleryURLs.count)")

            await refreshPet()

        } catch {

            print("❌ Failed to add gallery photos")
            print("❌ \(error.localizedDescription)")

            await MainActor.run {
                isRefreshing = false
            }
        }
    }
}

// MARK: - Hero

extension PetProfileView {

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
}

// MARK: - Profile Image

extension PetProfileView {

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
        .frame(
            width: 150,
            height: 150
        )
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

            Image(
                systemName: "pawprint.fill"
            )
            .font(
                .system(size: 55)
            )
            .foregroundColor(
                FurryTailsTheme.orange
            )
        }
    }
}

// MARK: - Identity

extension PetProfileView {

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
}

// MARK: - Personality

extension PetProfileView {

    private var personalitySection: some View {

        profileCard(
            title: "Personality",
            icon: "heart.fill"
        ) {

            VStack(
                alignment: .leading,
                spacing: 16
            ) {

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

                if let characteristics = currentPet.characteristics,
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
    
}

// MARK: - About

extension PetProfileView {

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
}


// MARK: - Gallery

extension PetProfileView {

   @ViewBuilder
   private var gallerySection: some View {
       if !currentPet.petGalleryURLs.isEmpty {
           VStack(alignment: .leading, spacing: 14) {

               // Gallery header
               HStack {
                   Image(systemName: "photo.on.rectangle")
                       .foregroundColor(FurryTailsTheme.orange)

                   Text("Photo Gallery")
                       .font(.headline)
                       .fontWeight(.bold)
                       .foregroundColor(FurryTailsTheme.primaryText)

                   Spacer()

                   Text("\(currentPet.petGalleryURLs.count) photos")
                       .font(.subheadline)
                       .foregroundColor(FurryTailsTheme.secondaryText)
               }

               // Card carousel
               TabView(selection: gallerySelection) {
                   ForEach(
                       Array(currentPet.petGalleryURLs.enumerated()),
                       id: \.element
                   ) { index, imageURL in
                       galleryCarouselCard(
                           imageURL: imageURL,
                           index: index
                       )
                       .tag(index)
                       .padding(.horizontal, 24)
                   }
               }
               .frame(height: 290)
               .tabViewStyle(.page(indexDisplayMode: .never))

               // Page indicators and counter
               HStack {
                   HStack(spacing: 6) {
                       ForEach(
                           currentPet.petGalleryURLs.indices,
                           id: \.self
                       ) { index in
                           Capsule()
                               .fill(
                                   index == selectedGalleryIndex
                                   ? FurryTailsTheme.orange
                                   : FurryTailsTheme.secondaryText
                                       .opacity(0.25)
                               )
                               .frame(
                                   width: index == selectedGalleryIndex ? 18 : 6,
                                   height: 6
                               )
                       }
                   }

                   Spacer()

                   Text(
                       "\(selectedGalleryIndex + 1) of \(currentPet.petGalleryURLs.count)"
                   )
                   .font(.caption)
                   .fontWeight(.semibold)
                   .foregroundColor(FurryTailsTheme.secondaryText)
               }
               .padding(.horizontal, 26)
           }
           .padding(.vertical, 8)
       }
   }

   private var gallerySelection: Binding<Int> {
       Binding(
           get: { selectedGalleryIndex },
           set: { selectedGalleryIndex = $0 }
       )
   }

   private func galleryCarouselCard(
       imageURL: String,
       index: Int
   ) -> some View {
       Group {
           if let url = URL(string: imageURL) {
               AsyncImage(url: url) { phase in
                   switch phase {
                   case .empty:
                       galleryCardPlaceholder
                           .overlay {
                               ProgressView()
                           }

                   case .success(let image):
                       image
                           .resizable()
                           .scaledToFill()
                           .frame(maxWidth: .infinity)
                           .frame(height: 270)
                           .clipped()

                   case .failure:
                       galleryCardPlaceholder

                   @unknown default:
                       galleryCardPlaceholder
                   }
               }
               .frame(height: 270)
               .clipShape(RoundedRectangle(cornerRadius: 22))
               .contentShape(RoundedRectangle(cornerRadius: 22))
               .overlay(alignment: .bottomLeading) {
                   LinearGradient(
                       colors: [.clear, .black.opacity(0.5)],
                       startPoint: .center,
                       endPoint: .bottom
                   )
                   .clipShape(RoundedRectangle(cornerRadius: 22))
                   .overlay(alignment: .bottomLeading) {
                       Label(
                           "Photo \(index + 1)",
                           systemImage: "pawprint.fill"
                       )
                       .font(.subheadline.weight(.semibold))
                       .foregroundColor(.white)
                       .padding(16)
                   }
                   .allowsHitTesting(false)
               }
               .overlay {
                   RoundedRectangle(cornerRadius: 22)
                       .strokeBorder(
                           Color.white.opacity(0.12),
                           lineWidth: 1
                       )
               }
               .shadow(
                   color: .black.opacity(0.12),
                   radius: 12,
                   x: 0,
                   y: 6
               )
               .onTapGesture {
                   selectedGalleryItem = GalleryViewerItem(url: url)
               }
               .accessibilityLabel("View photo \(index + 1)")
               .accessibilityAddTraits(.isButton)
           } else {
               galleryCardPlaceholder
                   .frame(height: 270)
           }
       }
   }

   private var galleryCardPlaceholder: some View {
       RoundedRectangle(cornerRadius: 22)
           .fill(
               FurryTailsTheme.orangeSoft.opacity(0.35)
           )
           .overlay {
               Image(systemName: "photo")
                   .font(.system(size: 34))
                   .foregroundColor(FurryTailsTheme.orange)
           }
   }
}

// MARK: - Reusable Card

extension PetProfileView {

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

                Image(
                    systemName: icon
                )
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
            RoundedRectangle(
                cornerRadius: 18
            )
        )
        .shadow(
            color: .black.opacity(0.05),
            radius: 8,
            y: 3
        )
        .padding(.horizontal)
    }
}

// MARK: - Profile Row

extension PetProfileView {

    private func profileRow(
        title: String,
        value: String,
        icon: String
    ) -> some View {

        HStack(spacing: 12) {

            Image(
                systemName: icon
            )
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
}

// MARK: - Microchip Privacy

extension PetProfileView {

    private func maskedChipNumber(
        _ chip: String
    ) -> String {

        guard chip.count > 4 else {
            return "••••"
        }

        let suffix = String(
            chip.suffix(4)
        )

        return "••••••••\(suffix)"
    }
}

// MARK: - Gallery Viewer Item

struct GalleryViewerItem: Identifiable {

    let id = UUID()
    let url: URL
}

// MARK: - Gallery Photo Viewer

struct GalleryPhotoViewer: View {

    let imageURL: URL
    let onAddPhotos: ([Data]) async -> Void
    let onDeletePhoto: (URL) async throws -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var showShareSheet = false
    @State private var showPostComposer = false
    
    @State private var showPhotoPicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []

    @State private var showDeleteConfirmation = false
    @State private var isDeletingPhoto = false
    @State private var deleteErrorMessage: String?
    @State private var showDeleteError = false


    var body: some View {

        ZStack {

            // MARK: - Background

            Color.black
                .ignoresSafeArea()


            // MARK: - Photo

            AsyncImage(url: imageURL) { phase in

                switch phase {

                case .empty:

                    VStack(spacing: 18) {

                        ProgressView()
                            .progressViewStyle(
                                CircularProgressViewStyle(
                                    tint: .white
                                )
                            )
                            .scaleEffect(1.5)

                        Text("Loading photo...")
                            .font(.headline)
                            .foregroundColor(.white)

                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )


                case .success(let image):

                    image
                        .resizable()
                        .scaledToFit()
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 70)


                case .failure:

                    VStack(spacing: 18) {

                        Image(
                            systemName:
                                "photo.badge.exclamationmark"
                        )
                        .font(
                            .system(size: 50)
                        )
                        .foregroundColor(
                            .white.opacity(0.8)
                        )

                        Text("Unable to load photo")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(
                            "Please check your connection and try again."
                        )
                        .font(.subheadline)
                        .foregroundColor(
                            .white.opacity(0.65)
                        )
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                        Button {
                            dismiss()
                        } label: {

                            Text("Close")
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )


                @unknown default:

                    ProgressView()
                        .tint(.white)
                }
            }


            // MARK: - Top Bar

            VStack {

                HStack {

                    VStack(
                        alignment: .leading,
                        spacing: 2
                    ) {

                        Text("Gallery")
                            .font(
                                .system(
                                    size: 18,
                                    weight: .bold
                                )
                            )
                            .foregroundColor(.white)

                        Text("Your Pet Photo")
                            .font(.caption)
                            .foregroundColor(
                                .white.opacity(0.65)
                            )
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {

                        Image(systemName: "xmark")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .bold
                                )
                            )
                            .foregroundColor(.white)
                            .frame(
                                width: 44,
                                height: 44
                            )
                            .background(
                                Color.black.opacity(0.60)
                            )
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)

                Spacer()
            }


            // MARK: - Bottom Action Bar

            VStack {

                Spacer()

                VStack(spacing: 12) {

                    // Photo counter

                    Text("1 / 1")
                        .font(
                            .system(
                                size: 13,
                                weight: .semibold
                            )
                        )
                        .foregroundColor(
                            .white.opacity(0.85)
                        )


                    // Glass toolbar

                    HStack(spacing: 0) {

                        // ADD

                        galleryActionButton(
                            icon: "plus",
                            title: "Add"
                        ) {
                            selectedPhotos = []
                            showPhotoPicker = true
                        }
                        
                        .photosPicker(
                            isPresented: $showPhotoPicker,
                            selection: $selectedPhotos,
                            maxSelectionCount: 10,
                            matching: .images
                        )
                        .onChange(of: selectedPhotos) { _, newItems in
                            guard !newItems.isEmpty else { return }

                            Task {
                                var imageDataArray: [Data] = []

                                for item in newItems {
                                    if let data = try? await item.loadTransferable(type: Data.self) {
                                        imageDataArray.append(data)
                                    }
                                }

                                guard !imageDataArray.isEmpty else { return }

                                await onAddPhotos(imageDataArray)

                                await MainActor.run {
                                    selectedPhotos = []
                                }
                            }
                        }

                        Spacer()


                        // SHARE

                        galleryActionButton(
                            icon: "square.and.arrow.up",
                            title: "Share"
                        ) {
                            showShareSheet = true
                        }


                        Spacer()


                        // POST

                        galleryActionButton(
                            icon: "paperplane.fill",
                            title: "Post"
                        ) {
                            showPostComposer = true
                        }
                        .sheet(isPresented: $showPostComposer) {
                            AddPostView(
                                initialImageURL: imageURL,
                                dismissAfterPosting: true
                            )
                        }
                        
                        
                        Spacer()

                        // DELETE
                        galleryActionButton(
                            icon: "trash",
                            title: isDeletingPhoto ? "Deleting..." : "Delete"
                        ) {
                            guard !isDeletingPhoto else { return }
                            showDeleteConfirmation = true
                        }
                        .disabled(isDeletingPhoto)

                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(
                            cornerRadius: 24
                        )
                    )
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: 24
                        )
                        .stroke(
                            Color.white.opacity(0.18),
                            lineWidth: 1
                        )
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
            }
        }
        .preferredColorScheme(.dark)


        // MARK: - Share Sheet

        .sheet(
            isPresented: $showShareSheet
        ) {

            ShareSheet(
                items: [
                    imageURL
                ]
            )
            .presentationDetents([
                .medium
            ])
        }
    }


    // MARK: - Action Button

    private func galleryActionButton(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            VStack(spacing: 5) {

                Image(systemName: icon)
                    .font(
                        .system(
                            size: 20,
                            weight: .semibold
                        )
                    )

                Text(title)
                    .font(
                        .system(
                            size: 11,
                            weight: .medium
                        )
                    )
            }
            .foregroundColor(.white)
            .frame(
                minWidth: 65
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Share Sheet

struct ShareSheet:
    UIViewControllerRepresentable {

    let items: [Any]

    func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {

        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController:
            UIActivityViewController,
        context: Context
    ) {
    }
}
