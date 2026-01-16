//
//  CreateAccountView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-31.
//

import SwiftUI
import FirebaseAuth

/// Screen for creating a new Firebase account.
struct CreateAccountView: View {
    
    // MARK: - Environment
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - User Inputs
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // MARK: - UI State
    @State private var localError: String?
    @State private var isCreating: Bool = false
    
    // MARK: - Validation
    private var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }
    
    private var canCreateAccount: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        isEmailValid &&
        password.count >= 6 &&
        password == confirmPassword &&
        !isCreating
    }
    
    var body: some View {
        ZStack {
            
            LinearGradient.esPrimaryGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                            .shadow(radius: 8)
                        
                        Text("Create Account")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        
                        Text("Set up your account to start splitting expenses.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 40)
                    
                    
                    // MARK: Card
                    ESCard {
                        VStack(spacing: 16) {
                            
                            if let error = localError {
                                Text(error)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .font(.footnote)
                            }
                            
                            // Full Name
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Full Name")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                TextField("Your name", text: $fullName)
                                    .textInputAutocapitalization(.words)
                                    .textFieldStyle(ESInputFieldStyle())
                            }
                            
                            // Email
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                TextField("you@example.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .textFieldStyle(ESInputFieldStyle())
                            }
                            
                            // Password
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Password")
                                    Spacer()
                                    if password.count > 0 && password.count < 6 {
                                        Text("min 6 chars")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                                SecureField("Enter password", text: $password)
                                    .textInputAutocapitalization(.never)
                                    .textFieldStyle(ESInputFieldStyle())
                            }
                            
                            // Confirm Password
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                SecureField("Re-enter password", text: $confirmPassword)
                                    .textInputAutocapitalization(.never)
                                    .textFieldStyle(ESInputFieldStyle())
                            }
                            
                            
                            Button {
                                Task { await createAccount() }
                            } label: {
                                HStack(spacing: 8) {
                                    if isCreating {
                                        ProgressView().tint(.white)
                                    }
                                    Text(isCreating ? "Creating..." : "Create Account")
                                        .font(.headline)
                                }
                            }
                            .buttonStyle(ESPrimaryButtonStyle())
                            .disabled(!canCreateAccount)
                            
                            
                            Button { dismiss() } label: {
                                Text("Already have an account? Sign In")
                                    .font(.footnote)
                                    .foregroundColor(.esPrimary)
                                    .underline()
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
        }
    }
    
    // MARK: - Sign Up Logic
    private func createAccount() async {
        guard canCreateAccount else {
            localError = "Please fill all fields correctly."
            return
        }
        
        localError = nil
        isCreating = true
        
        do {
            // 1. Create Firebase user
            let user = try await authService.signUp(email: email, password: password)
            
            // 2. Update display name in Firebase Auth
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = fullName
            
            try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<Void, Error>) in
                changeRequest.commitChanges { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
            
            // ⭐ 3. Save profile to Realtime Database
            let userService = UserService()
            try await userService.saveUserProfile(
                uid: user.uid,
                fullName: fullName,
                email: email
            )
            
            isCreating = false
            
        } catch {
            isCreating = false
            localError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        CreateAccountView()
            .environmentObject(AuthService.shared)
    }
}
