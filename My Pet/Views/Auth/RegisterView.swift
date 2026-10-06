//
//  RegisterView.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import SwiftUI

struct RegisterView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // 🐾 Title
            Text("Create Account 🐶")
                .font(.largeTitle.bold())
                .padding(.top, 40)

            // ✏️ Fields
            VStack(alignment: .leading, spacing: 12) {
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
            }

            // ⏳ Loading
            if authVM.isLoading {
                ProgressView("Creating account...")
                    .padding(.top)
            }

            // 🚀 Sign Up
            Button {
                Task {
                    guard !email.isEmpty, !password.isEmpty, !username.isEmpty else {
                        authVM.errorMessage = "Please fill in all fields."
                        return
                    }
                    await authVM.signUp(email: email, password: password, username: username)
                    if authVM.isAuthenticated {
                        dismiss()
                    }
                }
            } label: {
                Text("Sign Up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(authVM.isLoading ? Color.gray.gradient : Color.green.gradient)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(authVM.isLoading)

            // ⚠️ Error Message
            if let error = authVM.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .transition(.opacity.combined(with: .slide))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .animation(.easeInOut, value: authVM.errorMessage)
    }
}
