//  MyPetsView.swift
//  My Pet
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import SwiftUI
import FirebaseFirestore

struct MyPetsView: View {

    @EnvironmentObject var authVM: AuthViewModel

    @StateObject private var petService = PetService()

    @State private var selectedIndex = 0
    @State private var showAddPetView = false

    var body: some View {

        NavigationView {

            VStack {

                // MARK: - Main Pet Display

                if petService.pets.isEmpty {

                    VStack(spacing: 16) {

                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text("No Pets Yet")
                            .font(.title2)
                            .bold()

                        Text("Add your first pet to get started.")
                            .foregroundColor(.secondary)

                        Button {
                            print("🐾 Opening Add Pet")
                            showAddPetView = true
                        } label: {
                            Label("Add Pet", systemImage: "plus")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 50)

                } else {

                    let pet = petService.pets[selectedIndex]

                    AsyncImage(url: URL(string: pet.petImageURL)) { image in

                        image
                            .resizable()
                            .scaledToFill()
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 300,
                                maxHeight: 300
                            )
                            .clipped()
                            .cornerRadius(20)
                            .shadow(radius: 10)

                    } placeholder: {

                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.15))
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 300,
                                maxHeight: 300
                            )
                            .overlay {
                                ProgressView()
                            }
                    }

                    Text(pet.name)
                        .font(.title2)
                        .bold()

                    Text(pet.breed ?? pet.species)
                        .foregroundColor(.secondary)

                    // MARK: - Pet Carousel

                    ScrollView(
                        .horizontal,
                        showsIndicators: false
                    ) {

                        HStack(spacing: 16) {

                            ForEach(
                                petService.pets.indices,
                                id: \.self
                            ) { index in

                                let p = petService.pets[index]

                                VStack {

                                    AsyncImage(
                                        url: URL(
                                            string: p.petImageURL
                                        )
                                    ) { image in

                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(
                                                width: 100,
                                                height: 100
                                            )
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        index == selectedIndex
                                                        ? .blue
                                                        : .clear,
                                                        lineWidth: 3
                                                    )
                                            )

                                    } placeholder: {

                                        Circle()
                                            .fill(
                                                Color.gray.opacity(0.3)
                                            )
                                            .frame(
                                                width: 100,
                                                height: 100
                                            )
                                    }

                                    Text(p.name)
                                        .font(.caption)
                                }
                                .onTapGesture {
                                    selectedIndex = index
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)

                    Spacer()
                }
            }
            .padding()
            .navigationTitle("My Pets")

            // MARK: - Add Pet Button

            .toolbar {

                ToolbarItem(
                    placement: .navigationBarTrailing
                ) {

                    Button {

                        print("🐾 Opening Add Pet")
                        showAddPetView = true

                    } label: {

                        Image(systemName: "plus")
                    }
                }
            }

            // MARK: - Add Pet Sheet

            .sheet(isPresented: $showAddPetView) {

                AddPetView {

                    Task {

                        if let uid = authVM.currentUser?.id {

                            print("🐾 Refreshing pets for \(uid)")

                            await petService.fetchPets(
                                for: uid
                            )

                            print(
                                "🐾 MyPetsView now has \(petService.pets.count) pets"
                            )
                        }
                    }
                }
            }
        }

        // MARK: - Initial Pet Load

        .task {

            if let uid = authVM.currentUser?.id {

                print("🐾 MyPetsView fetching pets for \(uid)")

                await petService.fetchPets(
                    for: uid
                )

                print(
                    "🐾 MyPetsView loaded \(petService.pets.count) pets"
                )
            } else {

                print("❌ MyPetsView: No authenticated user")
            }
        }
    }
}
