//
//  ShareViewModel.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import Combine
import SwiftUI

final class ShareViewModel: ObservableObject {
    @Published var shareURL: URL?
    @Published var shareCount: Int = 0
    @Published var showShareSheet = false

    func generateShareLink(for post: Post) {
        // TODO:  generate sharelink logic here
    }
    func incrementShareCount(for post: Post) {
        // TODO:  increment Share Count logic here
    }
    func presentShareSheet(with items: [Any]) {
        // TODO: presentShareSheet logic here
    }
}
