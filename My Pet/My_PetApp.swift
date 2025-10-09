//
//  My_PetApp.swift
//  My Pet
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import SwiftUI
import CoreData

@main
struct My_PetApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
