//
//  Untitled.swift
//  My Pet
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import Foundation
import FirebaseFirestore

struct Pet: Identifiable, Codable {
    @DocumentID var id: String?

    var name: String
    var species: String
    var breed: String?
    var age: Int?
    var bio: String?

    var ownerId: String

    var character: String?
    var traits: String?

    var petImageURL: String
    var petGalleryURLs: String

    var createdAt: Date?
    var updatedAt: Date?

    init(
        id: String? = nil,
        name: String,
        species: String,
        breed: String? = nil,
        age: Int? = nil,
        bio: String? = nil,
        ownerId: String,
        character: String? = nil,
        traits: String? = nil,
        petImageURL: String = "",
        petGalleryURLs: String = "",
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.breed = breed
        self.age = age
        self.bio = bio
        self.ownerId = ownerId
        self.character = character
        self.traits = traits
        self.petImageURL = petImageURL
        self.petGalleryURLs = petGalleryURLs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
