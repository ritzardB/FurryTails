//
//  MediaItem.swift
//  My Pets
//
//  Created by Richard Balabarcon on 13/10/2025.
//
import Foundation

struct MediaItem: Identifiable, Codable {
    var id = UUID().uuidString
    var type: MediaType
    var url: String
}
