//
//  PetCardCarouselView.swift
//  My Pet
//
//  Created by Richard Balabarcon on 09/10/2026.
//


import SwiftUI
import FirebaseFirestore

struct PetCardCarouselView: View {

    // MARK: - Properties

    let ownerId: String

    @State private var pets: [Pet] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let db = Firestore.firestore()

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {

            if isLoading {
                loadingView

            } else if let errorMessage {
                errorView(message: errorMessage)

            } else if pets.isEmpty {
                emptyView

            } else {
                petCarousel

                // Page indicator
                if pets.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(pets.indices, id: \.self) { index in
                            Circle()
                                .fill(
                                    Color.primary.opacity(
                                        index == currentPage ? 0.8 : 0.2
                                    )
                                )
                                .frame(width: 7, height: 7)
                        }
                    }

                    Text("Swipe to explore your pets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .task(id: ownerId) {
            await fetchPets()
        }
    }

    // MARK: - Carousel

    @State private var currentPage = 0

    private var petCarousel: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(pets.enumerated()), id: \.element.id) { index, pet in
                PetFlipCardView(pet: pet)
                    .padding(.horizontal, 20)
                    .tag(index)
            }
        }
        .frame(height: 430)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .indexViewStyle(.page(backgroundDisplayMode: .never))
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()

            Text("Loading your furry pets...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
    }

    // MARK: - Empty State

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "pawprint.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Pets Yet")
                .font(.headline)

            Text("Your pets will appear here once you add them.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .padding()
    }

    // MARK: - Error State

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.orange)

            Text("Unable to Load Pets")
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await fetchPets()
                }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .padding()
    }

    // MARK: - Fetch Pets

    @MainActor
    private func fetchPets() async {
        guard !ownerId.isEmpty else {
            pets = []
            errorMessage = "The pet owner's ID is missing."
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let snapshot = try await db
                .collection("pets")
                .whereField("ownerId", isEqualTo: ownerId)
                .getDocuments()

            let fetchedPets = snapshot.documents.compactMap { document in
                try? document.data(as: Pet.self)
            }

            pets = fetchedPets.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name)
                    == .orderedAscending
            }

            currentPage = 0
            isLoading = false

        } catch {
            pets = []
            errorMessage = error.localizedDescription
            isLoading = false

            print(
                "PetCardCarouselView: Failed to fetch pets: \(error.localizedDescription)"
            )
        }
    }
}

#Preview {
    PetCardCarouselView(ownerId: "preview-owner")
}
