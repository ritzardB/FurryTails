//
//  Comment.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import Foundation

struct Comment: Identifiable, Codable {
    var id: String = UUID().uuidString
    var postId: String
    var ownerId: String
    var username: String
    var text: String
    var createdAt: Date = Date()
}
