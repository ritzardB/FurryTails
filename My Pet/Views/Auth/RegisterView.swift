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
        ZStack {

            // MARK: - Background Image

            Image("loginpet")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // MARK: - Dark Overlay

            Color.black.opacity(0.45)
                .ignoresSafeArea()

            // MARK: - Registration Content

            ScrollView {
                VStack(spacing: 22) {

                    // Push content down so the FurryTails logo
                    // remains visible in the background.
                    Spacer()
                        .frame(height: 185)

                    // MARK: - Title

                    VStack(spacing: 8) {

                        Text("🐾")
                            .font(.system(size: 50))

                        Text("Create Account")
                            .font(
                                .system(
                                    size: 32,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .foregroundColor(.white)

                        Text("Join the FurryTails community")
                            .font(.subheadline)
                            .foregroundColor(
                                .white.opacity(0.85)
                            )
                    }

                    // MARK: - Registration Fields

                    VStack(spacing: 12) {

                        TextField(
                            "Username",
                            text: $username
                        )
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                        TextField(
                            "Email",
                            text: $email
                        )
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                        SecureField(
                            "Password",
                            text: $password
                        )
                        .textFieldStyle(.roundedBorder)
                    }

                    // MARK: - Loading

                    if authVM.isLoading {
                        ProgressView(
                            "Creating account..."
                        )
                        .tint(.white)
                        .foregroundColor(.white)
                        .padding(.top, 4)
                    }

                    // MARK: - Sign Up

                    Button {

                        Task {

                            guard
                                !email.isEmpty,
                                !password.isEmpty,
                                !username.isEmpty
                            else {
                                authVM.errorMessage =
                                    "Please fill in all fields."
                                return
                            }

                            await authVM.signUp(
                                email: email,
                                password: password,
                                username: username
                            )

                            if authVM.isAuthenticated {
                                dismiss()
                            }
                        }

                    } label: {

                        Text("Create Account")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                authVM.isLoading
                                ? AnyShapeStyle(Color.gray)
                                : AnyShapeStyle(
                                    FurryTailsTheme.primaryGradient
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(authVM.isLoading)

                    // MARK: - Error

                    if let error = authVM.errorMessage {

                        Text(error)
                            .foregroundColor(.white)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(
                                .opacity.combined(with: .slide)
                            )
                    }

                    // MARK: - Back to Login

                    Button {
                        dismiss()
                    } label: {

                        Text("Already have an account? Sign in")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }

                    Spacer()
                        .frame(height: 38)
                }
                .padding(.horizontal, 24)
            }
        }
        .animation(
            .easeInOut,
            value: authVM.errorMessage
        )
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthViewModel())
    
}
