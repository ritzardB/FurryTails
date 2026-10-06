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
        VStack(spacing: 24) {
            Text("Welcome Back 🐾")
                .font(.largeTitle.bold())
                .padding(.top, 40)

            VStack(alignment: .leading, spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
            }

            if authVM.isLoading {
                ProgressView()
            }

            Button(action: {
                Task { await authVM.signIn(email: email, password: password) } }) {
                Text("Login")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.gradient)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            if let error = authVM.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Spacer()

            Button("Don’t have an account? Sign up now") {
                showRegister.toggle()
            }
            .font(.subheadline)
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
        .sheet(isPresented: $showRegister) {
            RegisterView().environmentObject(authVM)
        }
    }
}
