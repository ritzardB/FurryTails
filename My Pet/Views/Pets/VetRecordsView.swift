
import SwiftUI

struct VetRecordsView: View {
    
    let pet: Pet
    
        var body: some View {
            ZStack {
                // FurryTails background
                FurryTailsTheme.backgroundGradient
                    .ignoresSafeArea()

                List {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(pet.name)
                                .font(.title2.bold())
                                .foregroundStyle(.primary)

                            Text("\(pet.species) • \(pet.breed ?? "Breed not specified")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("Furry Pet Care Hub")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)

                    }

                    
                    Section("Health Records") {
                        Label {
                            Text("Medical History")
                        } icon: {
                            Image(systemName: "heart.text.clipboard")
                                .foregroundStyle(.red)
                        }

                        Label {
                            Text("Vaccinations")
                        } icon: {
                            Image(systemName: "syringe")
                                .foregroundStyle(.blue)
                        }

                        Label {
                            Text("Medications & Allergies")
                        } icon: {
                            Image(systemName: "pills")
                                .foregroundStyle(.orange)
                        }
                    }

                    Section("Vet Appointments") {
                        Label {
                            Text("Upcoming Appointments")
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundStyle(.blue)
                        }

                        Label {
                            Text("Past Visits")
                        } icon: {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.purple)
                        }
                    }

                    Section("Food & Nutrition") {
                        Label {
                            Text("Food Preferences")
                        } icon: {
                            Image(systemName: "fork.knife")
                                .foregroundStyle(.orange)
                        }

                        Label {
                            Text("Feeding Schedule")
                        } icon: {
                            Image(systemName: "clock")
                                .foregroundStyle(.blue)
                        }

                        Label {
                            Text("Dietary Restrictions")
                        } icon: {
                            Image(systemName: "leaf")
                                .foregroundStyle(.green)
                        }
                    }

                    Section("Care Reminders") {
                        Label {
                            Text("Vaccination Reminders")
                        } icon: {
                            Image(systemName: "bell")
                                .foregroundStyle(.orange)
                        }

                        Label {
                            Text("Medication Reminders")
                        } icon: {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(.purple)
                        }

                        Label {
                            Text("Routine Care")
                        } icon: {
                            Image(systemName: "checklist")
                                .foregroundStyle(.green)
                        }
                    }

                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
                .listRowBackground(Color.clear)
                .background(Color.clear)
                .navigationTitle("Pet Care Hub")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tint(.accentColor)
        }
    }

    #Preview {
        NavigationStack {
            VetRecordsView(
                pet: Pet(
                    name: "Lio",
                    species: "Dog",
                    ownerId: "preview-owner",
                    petImageURL: "",
                    petGalleryURLs: []
                )
            )
        }
    }
