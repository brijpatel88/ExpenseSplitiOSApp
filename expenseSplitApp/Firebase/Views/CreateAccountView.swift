//
//  CreateAccountView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-31.
//

import SwiftUI
import FirebaseAuth

struct CreateAccountView: View {
    // MARK: - State variables for user input
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // MARK: - State variables for UI control
    @State private var isCreating: Bool = false          // Controls loading spinner visibility
    @State private var creationError: String? = nil      // Displays error messages
    @State private var navigateToHome: Bool = false      // Triggers navigation after success
    
    // MARK: - Main View
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.purple.opacity(0.8), .blue.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    
                    Spacer(minLength: 40)
                    
                    // MARK: - Header / App title
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .shadow(radius: 8)
                        
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    // MARK: - Input fields
                    VStack(spacing: 15) {
                        // Email
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never) // ✅ modern API
                            .disableAutocorrection(true)
                            .keyboardType(.emailAddress)
                            .padding(.horizontal)
                        
                        // Password
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                        
                        // Confirm password
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                    }
                    
                    // MARK: - Create Account button
                    Button(action: createAccountTapped) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Account")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .shadow(radius: 5)
                    }
                    // Disable button if invalid input or while loading
                    .disabled(!canCreateAccount || isCreating)
                    
                    // MARK: - Error message
                    if let creationError = creationError {
                        Text(creationError)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // MARK: - Back to Sign In link
                    NavigationLink(destination: SignInView()) {
                        Text("Already have an account? Sign In")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .underline()
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
            }
            // MARK: - Navigate to HomeView after success
            .navigationDestination(isPresented: $navigateToHome) {
                HomeView()
            }
        }
    }
    
    // MARK: - Computed property to enable button only if valid
    private var canCreateAccount: Bool {
        // Basic validation: fields not empty and passwords match
        !email.isEmpty && !password.isEmpty && password == confirmPassword
    }
    
    // MARK: - Firebase create account logic
    private func createAccountTapped() {
        guard canCreateAccount else {
            creationError = "Passwords do not match or fields are empty."
            return
        }
        
        creationError = nil
        isCreating = true
        
        // Call Firebase Auth via AuthService helper
        AuthService.shared.signUp(email: email, password: password) { result in
            DispatchQueue.main.async {
                isCreating = false
                switch result {
                case .success(_):
                    // ✅ Delay a bit for smooth navigation animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToHome = true
                    }
                case .failure(let error):
                    creationError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Preview for SwiftUI Canvas
#Preview {
    CreateAccountView()
}
