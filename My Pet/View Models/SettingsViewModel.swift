//
//  SettingsViewModel.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//
import SwiftUI
import Combine


final class SettingsViewModel: ObservableObject {
    @Published var isDarkMode = false
    @Published var notificationsEnabled = true
    @Published var showLogoutAlert = false

    func toggleDarkMode()  {
        notificationsEnabled.toggle()
    }
    
    func toggleNotifications() {
        isDarkMode.toggle()
    }
    func deleteAccount() async {
        // TODo:  deleteAccount logic here
    }
}
