//
//  LoginView.swift
//  My Pets
//
//  Created by Richard Balabarcon on 09/10/2025.
//

import SwiftUI

struct LoginView: View {

    @State private var email = ""
    @State private var password = ""

    @EnvironmentObject var authVM: AuthViewModel

    @State private var showRegister = false

    var body: some View {
        ZStack {

            // MARK: - Background Image

            Image("loginpet")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // MARK: - Dark Overlay

            Color.black.opacity(0.45)
                .ignoresSafeArea()

            // MARK: - Login Content

            ScrollView {
                VStack(spacing: 22) {

                    Spacer()
                        .frame(height: 150)

                    // MARK: - Logo / Title

                    VStack(spacing: 8) {
                        Text("🐾")
                            .font(.system(size: 55))

                        Text("Welcome Back")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Sign in to continue to FurryTails")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                    }

                    // MARK: - Google Login

                    Button {
                        Task {
                            await authVM.signInWithGoogle()
                        }
                    } label: {

                        HStack(spacing: 12) {

                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20))

                            Text("Continue with Google")
                                .font(.headline)

                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .shadow(
                            color: .black.opacity(0.2),
                            radius: 5,
                            x: 0,
                            y: 3
                        )
                    }

                    // MARK: - Divider

                    HStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(height: 1)

                        Text("OR")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))

                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(height: 1)
                    }

                    // MARK: - Email Fields

                    VStack(spacing: 12) {

                        TextField(
                            "Email",
                            text: $email
                        )
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                        SecureField(
                            "Password",
                            text: $password
                        )
                        .textFieldStyle(.roundedBorder)
                    }

                    // MARK: - Loading

                    if authVM.isLoading {
                        ProgressView()
                            .tint(.white)
                    }

                    // MARK: - Email Login

                    Button {
                        Task {
                            await authVM.signIn(
                                email: email,
                                password: password
                            )
                        }
                    } label: {

                        Text("Login")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Color.blue.gradient
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    // MARK: - Error

                    if let error = authVM.errorMessage {

                        Text(error)
                            .foregroundColor(.white)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // MARK: - Register

                    Button {
                        showRegister.toggle()
                    } label: {

                        Text("Don't have an account? Sign up now")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }

                    Spacer()
                        .frame(height: 30)
                }
                .padding(.horizontal, 24)
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
                .environmentObject(authVM)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
