//
//  ForgotPasswordView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-31.
//

import SwiftUI
import FirebaseAuth //Here Import FirebaseAuth

struct ForgotPasswordView: View {
    // MARK: - State variables
    @State private var email: String = ""                  // stores user input email
    @State private var message: String? = nil              // success or error message text
    @State private var isSending: Bool = false             // loading indicator control
    
    // MARK: - Main View Body
    var body: some View {
        ZStack {
            // MARK: - Background gradient
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer(minLength: 40)
                
                // MARK: - Header section
                VStack(spacing: 8) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .shadow(radius: 8)
                    
                    Text("Forgot Password?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Enter your registered email below to receive a password reset link.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                
                // MARK: - Email input field
                TextField("Enter your email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // MARK: - Send reset link button
                Button(action: sendPasswordReset) {
                    HStack {
                        if isSending {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Send Reset Link")
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
                .disabled(email.isEmpty) // disabled until user types an email
                
                // MARK: - Message section
                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(message.contains("sent") ? .green : .red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.top, 5)
                }
                
                // MARK: - Back to Sign In link
                NavigationLink(destination: SignInView()) {
                    Text("Back to Sign In")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .underline()
                }
                .padding(.top, 15)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Firebase reset password logic
    private func sendPasswordReset() {
        guard !email.isEmpty else { return }
        
        isSending = true
        message = nil
        
        // Call Firebase's built-in method to send reset email
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                isSending = false
                if let error = error {
                    // Display readable Firebase error message
                    message = error.localizedDescription
                } else {
                    // Show success confirmation
                    message = "Password reset link has been sent to your email."
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
}

