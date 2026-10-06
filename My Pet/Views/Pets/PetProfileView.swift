//
//  PetProfileView.swift
//  My Pet
//
//  Created by Richard Balabarcon on 12/10/2025.
//

import SwiftUI
import FirebaseFirestore
import Combine

struct PetProfileView: View {
    var pet: Pet
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 🐾 Profile Image
                if let imageURL = URL(string: pet.petImageURL) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                            
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                            
                        case .failure:
                            Image(systemName: "pawprint")
                                .resizable()
                                .scaledToFit()
                            
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "pawprint.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.orange.opacity(0.8))
                }
                
                // 🐶 Pet Info
                VStack(spacing: 8) {
                    Text(pet.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let breed = pet.breed {
                        Text("\(pet.species) • \(breed)")
                            .font(.headline)
                            .foregroundColor(.gray)
                    } else {
                        Text(pet.species)
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    
                    if let age = pet.age {
                        Text("Age: \(age) years old")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let bio = pet.bio {
                        Text(bio)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                }
                
                Divider().padding(.vertical, 10)
                
                // 🧬 Character & Traits
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Character:")
                            .font(.headline)
                        Text(pet.character ?? "Not specified")
                            .font(.title2)
                    }
                    
                    Text("Traits:")
                        .font(.headline)
                    Text(pet.traits ?? "No traits specified")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // 🖼️ Gallery
                if !pet.petGalleryURLs.isEmpty {
                    Text("Gallery")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    if let url = URL(string: pet.petGalleryURLs),
                       let scheme = url.scheme,
                       ["http", "https"].contains(scheme.lowercased()) {
                        
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 120, height: 120)
                                
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 12)
                                    )
                                
                            case .failure:
                                Image(systemName: "photo")
                                    .frame(width: 120, height: 120)
                                
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
            }
        }
    }
}
