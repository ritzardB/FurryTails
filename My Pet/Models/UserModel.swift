//
//  UserModel.swift
//  My Pet
//
//  Created by Richard Balabarcon on 21/10/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct UserModel: Identifiable, Codable {
    @DocumentID var id: String?  // Firestore-managed ID
    var username: String
    var email: String
    var profileImageURL: String?
    var petImageURL: String?
    var bio: String?
    var pets: [String]?
    var followers: [String] = []
    var following: [String] = []
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
}
