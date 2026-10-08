//
//  Pet.swift
//  My Pet
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import Foundation
import FirebaseFirestore

struct Pet: Identifiable, Codable {

    @DocumentID var id: String?

    // MARK: - Basic Identity

    var name: String
    var species: String
    var breed: String?
    var age: Int?
    var sex: String?
    var color: String?
    var distinguishingMarks: String?
    var microchipNumber: String?

    // MARK: - About

    var bio: String?

    // MARK: - Personality

    var character: String?
    var traits: String?
    var characteristics: String?

    // MARK: - Ownership

    var ownerId: String

    // MARK: - Media

    var petImageURL: String
    var petGalleryURLs: [String]

    // MARK: - Timestamps

    var createdAt: Date?
    var updatedAt: Date?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {

        case id
        case name
        case species
        case breed
        case age
        case sex
        case color
        case distinguishingMarks
        case microchipNumber
        case bio
        case ownerId
        case character
        case traits
        case characteristics
        case petImageURL
        case petGalleryURLs
        case createdAt
        case updatedAt
    }

    // MARK: - Initializer

    init(
        id: String? = nil,
        name: String,
        species: String,
        breed: String? = nil,
        age: Int? = nil,
        sex: String? = nil,
        color: String? = nil,
        distinguishingMarks: String? = nil,
        microchipNumber: String? = nil,
        bio: String? = nil,
        ownerId: String,
        character: String? = nil,
        traits: String? = nil,
        characteristics: String? = nil,
        petImageURL: String = "",
        petGalleryURLs: [String] = [],
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {

        self.id = id
        self.name = name
        self.species = species
        self.breed = breed
        self.age = age
        self.sex = sex
        self.color = color
        self.distinguishingMarks = distinguishingMarks
        self.microchipNumber = microchipNumber
        self.bio = bio
        self.ownerId = ownerId
        self.character = character
        self.traits = traits
        self.characteristics = characteristics
        self.petImageURL = petImageURL
        self.petGalleryURLs = petGalleryURLs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Backward-Compatible Decoder

    init(from decoder: Decoder) throws {

        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        self.id = try container.decodeIfPresent(
            String.self,
            forKey: .id
        )

        self.name = try container.decodeIfPresent(
            String.self,
            forKey: .name
        ) ?? ""

        self.species = try container.decodeIfPresent(
            String.self,
            forKey: .species
        ) ?? ""

        self.breed = try container.decodeIfPresent(
            String.self,
            forKey: .breed
        )

        self.age = try container.decodeIfPresent(
            Int.self,
            forKey: .age
        )

        self.sex = try container.decodeIfPresent(
            String.self,
            forKey: .sex
        )

        self.color = try container.decodeIfPresent(
            String.self,
            forKey: .color
        )

        self.distinguishingMarks = try container.decodeIfPresent(
            String.self,
            forKey: .distinguishingMarks
        )

        self.microchipNumber = try container.decodeIfPresent(
            String.self,
            forKey: .microchipNumber
        )

        self.bio = try container.decodeIfPresent(
            String.self,
            forKey: .bio
        )

        self.ownerId = try container.decodeIfPresent(
            String.self,
            forKey: .ownerId
        ) ?? ""

        self.character = try container.decodeIfPresent(
            String.self,
            forKey: .character
        )

        self.traits = try container.decodeIfPresent(
            String.self,
            forKey: .traits
        )

        self.characteristics = try container.decodeIfPresent(
            String.self,
            forKey: .characteristics
        )

        self.petImageURL = try container.decodeIfPresent(
            String.self,
            forKey: .petImageURL
        ) ?? ""

        // --------------------------------------------------
        // Backward compatibility:
        //
        // Old Firestore documents:
        // petGalleryURLs: ""
        //
        // New Firestore documents:
        // petGalleryURLs: ["url1", "url2", "url3"]
        // --------------------------------------------------

        if let galleryURLs = try? container.decode(
            [String].self,
            forKey: .petGalleryURLs
        ) {

            self.petGalleryURLs = galleryURLs

        } else if let legacyGalleryURL =
            try? container.decode(
                String.self,
                forKey: .petGalleryURLs
            ) {

            if legacyGalleryURL.isEmpty {

                self.petGalleryURLs = []

            } else {

                self.petGalleryURLs = [
                    legacyGalleryURL
                ]
            }

        } else {

            self.petGalleryURLs = []
        }

        self.createdAt = try container.decodeIfPresent(
            Date.self,
            forKey: .createdAt
        )

        self.updatedAt = try container.decodeIfPresent(
            Date.self,
            forKey: .updatedAt
        )
    }
}
