//
//  VetClinicSearchView.swift
//  My Pet
//
//  Created by Richard Balabarcon on 09/10/2026.
//


import SwiftUI
import MapKit
import CoreLocation

struct VetClinicSearchView: View {
    @State private var searchText = ""
    @State private var searchByCity = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 24.4539,
            longitude: 54.3773
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 0.08,
            longitudeDelta: 0.08
        )
    )

    @State private var clinics: [MKMapItem] = []
    @State private var isSearching = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            Picker("Search method", selection: $searchByCity) {
                Text("Nearby (5 km)").tag(false)
                Text("Search city").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            HStack {
                TextField(
                    searchByCity ? "Enter city" : "Optional area or clinic",
                    text: $searchText
                )
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()

                Button {
                    Task {
                        await searchClinics()
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                }
                .disabled(isSearching)
            }
            .padding(.horizontal)

            if isSearching {
                ProgressView("Searching veterinary clinics...")
                    .padding()
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            if !clinics.isEmpty {
                Map(
                    initialPosition: .region(region),
                    content: {
                        ForEach(
                            Array(clinics.enumerated()),
                            id: \.offset
                        ) { _, clinic in
                            if let coordinate = clinic.placemark.location?.coordinate {
                                Marker(
                                    clinic.name ?? "Veterinary Clinic",
                                    coordinate: coordinate
                                )
                            }
                        }
                    }
                )
                .frame(height: 250)

                List {
                    ForEach(
                        Array(clinics.enumerated()),
                        id: \.offset
                    ) { _, clinic in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(clinic.name ?? "Veterinary Clinic")
                                .font(.headline)

                            if let address = clinic.placemark.title {
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if let phone = clinic.phoneNumber {
                                Text(phone)
                                    .font(.subheadline)
                            }

                            Button("Get Directions") {
                                clinic.openInMaps()
                            }
                            .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else if !isSearching {
                ContentUnavailableView(
                    "Find a Veterinary Clinic",
                    systemImage: "cross.case",
                    description: Text(
                        "Search nearby clinics within 5 km or enter a city."
                    )
                )
            }

            Spacer(minLength: 0)
        }
        .navigationTitle("Find a Vet")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await searchClinics()
        }
    }

    @MainActor
    private func searchClinics() async {
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        do {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = searchText.isEmpty
                ? "veterinary clinic"
                : "veterinary clinic \(searchText)"

            if searchByCity {
                let geocoder = CLGeocoder()
                let placemarks = try await geocoder.geocodeAddressString(
                    searchText
                )

                guard let location = placemarks.first?.location else {
                    errorMessage = "City not found. Try another city name."
                    clinics = []
                    return
                }

                request.region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.25,
                        longitudeDelta: 0.25
                    )
                )
            } else {
                request.region = region
            }

            request.resultTypes = .pointOfInterest

            let response = try await MKLocalSearch(
                request: request
            ).start()

            var results = response.mapItems

            if !searchByCity {
                let center = CLLocation(
                    latitude: region.center.latitude,
                    longitude: region.center.longitude
                )

                results = results.filter { item in
                    guard let location = item.placemark.location else {
                        return false
                    }
                    return location.distance(from: center) <= 5_000
                }
            }

            clinics = results

            if let first = results.first?.placemark.location?.coordinate {
                region.center = first
            }

            if results.isEmpty {
                errorMessage = "No matching clinics found. Try another search."
            }
        } catch {
            clinics = []
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationView {
        VetClinicSearchView()
    }
}
