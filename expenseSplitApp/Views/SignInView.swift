//
//  SignInView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-31.
//

import SwiftUI
import FirebaseAuth

/// Sign-in screen for the app.
/// Uses AuthService to sign the user in, then RootView switches to ContentView.
struct SignInView: View {
    
    // MARK: - Environment
    @EnvironmentObject var authService: AuthService
    
    // MARK: - UI State
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var isSigningIn: Bool = false
    @State private var errorMessage: String?
    
    @State private var goToCreateAccount = false
    @State private var goToForgotPassword = false
    
    private var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }
    
    private var canSignIn: Bool {
        isEmailValid && password.count >= 6 && !isSigningIn
    }
    
    var body: some View {
        ZStack {
            
            LinearGradient.esPrimaryGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    VStack(spacing: 8) {
                        Image(systemName: "creditcard.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.white)
                            .shadow(radius: 10)
                        
                        Text("Expense Splitter")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                        
                        Text("Sign in to manage your shared expenses")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.top, 40)
                    
                    
                    ESCard {
                        VStack(spacing: 18) {
                            
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .font(.footnote)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                TextField("you@example.com", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .keyboardType(.emailAddress)
                                    .textFieldStyle(ESInputFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Password")
                                    Spacer()
                                    if password.count > 0 && password.count < 6 {
                                        Text("min 6 characters")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                
                                HStack {
                                    Group {
                                        if showPassword {
                                            TextField("Enter password", text: $password)
                                        } else {
                                            SecureField("Enter password", text: $password)
                                        }
                                    }
                                    .textInputAutocapitalization(.never)
                                    
                                    Button { showPassword.toggle() } label: {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .textFieldStyle(ESInputFieldStyle())
                            }
                            
                            
                            Button(action: signInTapped) {
                                HStack(spacing: 10) {
                                    if isSigningIn {
                                        ProgressView().tint(.white)
                                    }
                                    Text(isSigningIn ? "Signing in…" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .buttonStyle(ESPrimaryButtonStyle())
                            .disabled(!canSignIn)
                            
                            HStack {
                                Button { goToForgotPassword = true } label: {
                                    Text("Forgot password?")
                                        .font(.footnote)
                                        .foregroundColor(.esPrimary)
                                }
                                
                                Spacer()
                                
                                Button { goToCreateAccount = true } label: {
                                    Text("Create account")
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.esPrimary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationDestination(isPresented: $goToCreateAccount) {
            CreateAccountView()
        }
        .navigationDestination(isPresented: $goToForgotPassword) {
            ForgotPasswordView()
        }
    }
    
    
    // MARK: - SIGN IN LOGIC
    private func signInTapped() {
        guard canSignIn else { return }
        
        errorMessage = nil
        isSigningIn = true
        
        authService.signIn(email: email, password: password) { result in
            DispatchQueue.main.async {
                self.isSigningIn = false
                
                switch result {
                case .success:
                    
                    // ⭐ Ensure user profile exists in database
                    Task {
                        if let user = Auth.auth().currentUser {
                            let userService = UserService()
                            let exists = try? await userService.fetchUser(uid: user.uid)
                            
                            if exists == nil {
                                try? await userService.saveUserProfile(
                                    uid: user.uid,
                                    fullName: user.displayName ?? "Unknown",
                                    email: user.email ?? ""
                                )
                            }
                        }
                    }
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SignInView()
            .environmentObject(AuthService.shared)
    }
}
