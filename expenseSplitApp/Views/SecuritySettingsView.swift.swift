//
//  SecuritySettingsView.swift.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-21.
//


import SwiftUI
import FirebaseAuth

/// Screen for security-related settings:
/// - Change Password (re-auth with current password)
/// - Face ID / biometric toggle (stored locally via @AppStorage)
struct SecuritySettingsView: View {
    
    // MARK: - Environment
    @EnvironmentObject var authService: AuthService
    
    // MARK: - Password fields
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmNewPassword: String = ""
    
    @State private var isChangingPassword: Bool = false
    @State private var passwordErrorMessage: String?
    @State private var passwordSuccessMessage: String?
    
    // MARK: - Face ID toggle
    @AppStorage("useFaceID") private var useFaceID: Bool = false
    
    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Change Password Card
                    ESCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Change Password")
                                .font(.headline)
                            
                            SecureFieldRow(
                                title: "Current Password",
                                text: $currentPassword
                            )
                            
                            SecureFieldRow(
                                title: "New Password",
                                text: $newPassword,
                                placeholder: "Min 6 characters"
                            )
                            
                            SecureFieldRow(
                                title: "Confirm New Password",
                                text: $confirmNewPassword
                            )
                            
                            if let passwordErrorMessage {
                                Text(passwordErrorMessage)
                                    .font(.footnote)
                                    .foregroundColor(.red)
                            }
                            
                            if let passwordSuccessMessage {
                                Text(passwordSuccessMessage)
                                    .font(.footnote)
                                    .foregroundColor(.green)
                            }
                            
                            Button {
                                changePasswordTapped()
                            } label: {
                                HStack {
                                    if isChangingPassword {
                                        ProgressView().tint(.white)
                                    }
                                    Text(isChangingPassword ? "Updating…" : "Update Password")
                                        .font(.headline)
                                }
                            }
                            .buttonStyle(ESPrimaryButtonStyle())
                            .disabled(isChangingPassword)
                        }
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Face ID Card
                    ESCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Face ID / Biometric Login")
                                .font(.headline)
                            
                            Toggle(isOn: $useFaceID) {
                                Text("Enable Face ID for quick sign-in")
                            }
                            .tint(.esPrimary)
                            
                            Text("When enabled, your app can later use Face ID / biometrics on this device to help sign in faster. (You still keep your email + password.)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 30)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Security & Password")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Actions
    
    private func changePasswordTapped() {
        passwordErrorMessage = nil
        passwordSuccessMessage = nil
        
        guard !currentPassword.isEmpty,
              !newPassword.isEmpty,
              !confirmNewPassword.isEmpty else {
            passwordErrorMessage = "Please fill in all fields."
            return
        }
        
        guard newPassword.count >= 6 else {
            passwordErrorMessage = "New password must be at least 6 characters."
            return
        }
        
        guard newPassword == confirmNewPassword else {
            passwordErrorMessage = "New passwords do not match."
            return
        }
        
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            passwordErrorMessage = "You must be logged in to change your password."
            return
        }
        
        isChangingPassword = true
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        // 1) Re-authenticate
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isChangingPassword = false
                    self.passwordErrorMessage = "Re-authentication failed: \(error.localizedDescription)"
                }
                return
            }
            
            // 2) Update password
            user.updatePassword(to: self.newPassword) { error in
                DispatchQueue.main.async {
                    self.isChangingPassword = false
                    if let error = error {
                        self.passwordErrorMessage = error.localizedDescription
                    } else {
                        self.passwordSuccessMessage = "Password updated successfully."
                        self.currentPassword = ""
                        self.newPassword = ""
                        self.confirmNewPassword = ""
                    }
                }
            }
        }
    }
}

// MARK: - Helper SecureField Row

private struct SecureFieldRow: View {
    let title: String
    @Binding var text: String
    var placeholder: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            SecureField(placeholder ?? title, text: $text)
                .textInputAutocapitalization(.never)
                .padding(10)
                .background(Color("CardBackground"))
                .cornerRadius(10)
        }
    }
}

#Preview {
    NavigationStack {
        SecuritySettingsView()
            .environmentObject(AuthService.shared)
    }
}
