//
//  ForgotPasswordView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-31.
//

import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var email: String = ""
    @State private var isSending: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    // Validation
    private var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }
    
    private var canSend: Bool {
        isEmailValid && !isSending
    }
    
    var body: some View {
        ZStack {
            
            // MARK: - THEME BACKGROUND
            LinearGradient.esPrimaryGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: Header
                    VStack(spacing: 8) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                            .shadow(radius: 10)
                        
                        Text("Reset Password")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        
                        Text("Enter your email and we will send you a password reset link.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 40)
                    
                    
                    // MARK: Card
                    ESCard {
                        VStack(spacing: 20) {
                            
                            // Errors
                            if let error = errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .font(.footnote)
                            }
                            
                            // Success
                            if let success = successMessage {
                                Text(success)
                                    .foregroundColor(.green)
                                    .multilineTextAlignment(.center)
                                    .font(.footnote)
                            }
                            
                            // Email Field
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
                            
                            
                            // MARK: Send Reset Button
                            Button(action: sendResetLink) {
                                HStack {
                                    if isSending {
                                        ProgressView().tint(.white)
                                    }
                                    Text(isSending ? "Sending..." : "Send Reset Link")
                                        .font(.headline)
                                }
                            }
                            .buttonStyle(ESPrimaryButtonStyle())
                            .disabled(!canSend)
                            
                            
                            // Back button
                            Button { dismiss() } label: {
                                Text("Back to Sign In")
                                    .font(.footnote)
                                    .underline()
                                    .foregroundColor(.esPrimary)
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
    
    
    // MARK: - Send Reset Logic
    private func sendResetLink() {
        guard isEmailValid else {
            errorMessage = "Please enter a valid email."
            return
        }
        
        errorMessage = nil
        successMessage = nil
        isSending = true
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                isSending = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    successMessage = "A reset link has been sent to your email."
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
}
