//
//  SignInView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-31.
//

import SwiftUI
import FirebaseAuth // ✅ Import Firebase Authentication framework

struct SignInView: View {
    // MARK: - UI State Variables
    @State private var email: String = ""               // User's email input
    @State private var password: String = ""            // User's password input
    @State private var showPassword: Bool = false       // Toggles show/hide password
    @State private var isSigningIn: Bool = false        // Controls loading spinner
    @State private var signInError: String? = nil       // Stores any Firebase error message

    // MARK: - Navigation States
    @State private var goToCreateAccount = false        // Navigate to Create Account
    @State private var goToForgotPassword = false       // Navigate to Forgot Password
    @State private var navigateToHome = false           // Navigate to Home after successful sign-in
    @State private var navigateToSkip = false           // Navigate to SkipSignInView

    // MARK: - Form Validation
    private var isEmailValid: Bool {
        // Basic check that email contains @ and .
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    private var canSignIn: Bool {
        // Sign-in allowed only if valid email and password length >= 6
        return isEmailValid && password.count >= 6 && !isSigningIn
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color("AccentStart"), Color("AccentEnd")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: App Logo and Title
                        VStack(spacing: 8) {
                            Image(systemName: "creditcard.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 72, height: 72)
                                .foregroundColor(.white)
                                .shadow(radius: 6)

                            Text("Expense Splitter")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 36)

                        // MARK: - Sign In Card
                        VStack(spacing: 16) {
                            // Show Firebase errors if any
                            if let error = signInError {
                                Text(error)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .font(.footnote)
                                    .padding(.horizontal)
                                    .transition(.opacity)
                            }

                            // MARK: Email Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                TextField("you@example.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .padding()
                                    .background(Color(uiColor: .systemGray6))
                                    .cornerRadius(10)
                            }

                            // MARK: Password Field
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Password")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Text(password.count < 6 ? "min 6 chars" : "")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }

                                HStack {
                                    if showPassword {
                                        TextField("Enter password", text: $password)
                                            .textContentType(.password)
                                            .autocapitalization(.none)
                                            .textInputAutocapitalization(.never)
                                            .disableAutocorrection(true)
                                    } else {
                                        SecureField("Enter password", text: $password)
                                            .textContentType(.password)
                                            .autocapitalization(.none)
                                            .textInputAutocapitalization(.never)
                                    }

                                    // Eye icon to toggle visibility
                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color(uiColor: .systemGray6))
                                .cornerRadius(10)
                            }

                            // MARK: Sign In Button
                            Button(action: signInTapped) {
                                HStack {
                                    if isSigningIn {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    }
                                    Text(isSigningIn ? "Signing in..." : "Sign In")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(canSignIn ? Color.accentColor : Color.gray.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .animation(.easeInOut, value: canSignIn)
                            }
                            .disabled(!canSignIn)
                            .padding(.top, 4)

                            // MARK: Forgot Password / Create Account Links
                            HStack {
                                Button(action: { goToForgotPassword = true }) {
                                    Text("Forgot password?")
                                        .font(.footnote)
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Button(action: { goToCreateAccount = true }) {
                                    Text("Create account")
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 2)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                        .padding(.horizontal)

                        // MARK: Social Sign-in (visual only)
                        VStack(spacing: 12) {
                            Text("Or continue with")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.9))

                            HStack(spacing: 14) {
                                SignInSocialButton(imageName: "applelogo", title: "Apple")
                                SignInSocialButton(imageName: "globe", title: "Web")
                            }
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 18)

                        // MARK: Skip Option (last)
                        Button(action: { navigateToSkip = true }) {
                            Text("Skip for now")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 36)
                    }
                    .padding(.vertical)
                }
            }
            // MARK: Navigation Destinations
            .navigationDestination(isPresented: $goToCreateAccount) {
                CreateAccountView()
            }
            .navigationDestination(isPresented: $goToForgotPassword) {
                ForgotPasswordView()
            }
            .navigationDestination(isPresented: $navigateToHome) {
                ContentView()
            }
            .navigationDestination(isPresented: $navigateToSkip) {
                ContentView()
            }
        }
    }

    // MARK: - Firebase Sign In Function
    private func signInTapped() {
        guard canSignIn else { return }

        // Reset errors & show loading spinner
        signInError = nil
        isSigningIn = true

        // Call Firebase Authentication
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                isSigningIn = false

                if let error = error {
                    // Show Firebase error message
                    signInError = error.localizedDescription
                    print("Sign-in failed: \(error.localizedDescription)")
                } else if let user = result?.user {
                    // Successful sign in!
                    print("✅ Signed in as: \(user.email ?? "Unknown email")")
                    navigateToHome = true
                } else {
                    // Should not happen, but good fallback
                    signInError = "Unexpected error during sign-in. Please try again."
                }
            }
        }
    }
}

// MARK: - Small Social Button Component
fileprivate struct SignInSocialButton: View {
    let imageName: String
    let title: String

    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: imageName)
                    .frame(width: 18, height: 18)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Color.white.opacity(0.12))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    SignInView()
}

