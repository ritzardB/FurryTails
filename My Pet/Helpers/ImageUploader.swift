//
//  ImageUploader.swift
//  My Pet
//
//  Created by Richard Balabarcon on 31/10/2025.
//

import UIKit
import FirebaseStorage

struct ImageUploader {
    static func uploadImage(image: UIImage, path: String) async throws -> String {
        let storageRef = Storage.storage().reference().child("\(path)/\(UUID().uuidString).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "InvalidImageData", code: 0, userInfo: nil)
        }
        
        _ = try await storageRef.putDataAsync(imageData)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
}
