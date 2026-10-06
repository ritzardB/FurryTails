//
//  PetCardView.swift
//  My Pet
//
//  Created by Richard Balabarcon on 05/11/2025.
//


import SwiftUI

struct PetCardView: View {
    let pet: Pet

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AsyncImage(url: URL(string: pet.petImageURL)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(height: 250)
            .clipped()
            .cornerRadius(16)

            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.headline)
                Text(pet.species)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            Divider()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}
