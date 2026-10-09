//
//  VetRecordsPetPickerView.swift
//  My Pet
//
//  Created by Richard Balabarcon on 09/10/2026.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct VetRecordsPetPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var pets: [Pet] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            
            ZStack {
                FurryTailsTheme.backgroundGradient
                    .ignoresSafeArea()
                Group {
                    if isLoading {
                        ProgressView("Loading your pets...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                    } else if let errorMessage {
                        ContentUnavailableView(
                            "Couldn't Load Pets",
                            systemImage: "exclamationmark.triangle",
                            description: Text(errorMessage)
                        )
                        
                    } else if pets.isEmpty {
                        ContentUnavailableView(
                            "No Pets Yet",
                            systemImage: "pawprint",
                            description: Text(
                                "Add a pet to manage its veterinary records."
                            )
                        )
                        
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(pets) { pet in
                                    NavigationLink {
                                        VetRecordsView(pet: pet)
                                    } label: {
                                        petCard(pet)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                    }
                }
                .navigationTitle("Furry Vet Records")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .task {
                    await fetchPets()
                }
            }
        }
    }

    private func petCard(_ pet: Pet) -> some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: pet.petImageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                case .empty, .failure:
                    Image(systemName: "pawprint.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                        .padding(12)

                @unknown default:
                    Image(systemName: "pawprint.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                        .padding(12)
                }
            }
            .frame(width: 82, height: 82)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 5) {
                Text(pet.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(pet.breed ?? pet.species)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(pet.species)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("View care records", systemImage: "heart.text.clipboard")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tint)
                    .padding(.top, 3)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }

    @MainActor
    private func fetchPets() async {
        guard let ownerId = Auth.auth().currentUser?.uid else {
            errorMessage = "Please sign in to view your pets."
            isLoading = false
            return
        }

        do {
            let snapshot = try await db
                .collection("pets")
                .whereField("ownerId", isEqualTo: ownerId)
                .getDocuments()

            pets = snapshot.documents.compactMap { document in
                try? document.data(as: Pet.self)
            }

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

#Preview {
    VetRecordsPetPickerView()
}
