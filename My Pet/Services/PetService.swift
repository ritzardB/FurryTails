//
//  PetService.swift
//  My Pet
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class PetService: ObservableObject {
    @Published var pets: [Pet] = []

    private let db = Firestore.firestore()

    func fetchPets(for ownerId: String) async {
        do {
            let snapshot = try await db
                .collection("pets")
                .whereField("ownerId", isEqualTo: ownerId)
                .order(by: "createdAt", descending: true)
                .getDocuments()

            var loadedPets: [Pet] = []

            for document in snapshot.documents {
                do {
                    let pet = try document.data(as: Pet.self)
                    loadedPets.append(pet)

                    print("🐾 Decoded pet: \(pet.name)")
                } catch {
                    print("❌ Failed to decode pet \(document.documentID)")
                    print("❌ Error: \(error)")
                    print("📄 Data: \(document.data())")
                }
            }

            self.pets = loadedPets

            print("🐾 Loaded \(pets.count) pets for \(ownerId)")

        } catch {
            print("❌ Error fetching pets: \(error.localizedDescription)")
        }
    }
}
