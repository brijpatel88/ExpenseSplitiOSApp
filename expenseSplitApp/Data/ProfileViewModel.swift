//
//  ProfileViewModel.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-06.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseDatabase

/// ViewModel for ProfileView.
/// - Loads/saves profile data from Realtime Database: /users/{uid}
/// - Manages preferences (currency, timezone, language)
/// - Handles password change and delete account flows.
class ProfileViewModel: ObservableObject {
    
    // MARK: - Profile Fields (shown in UI)
    @Published var fullName: String = ""
    @Published var email: String = ""       // read-only in UI
    @Published var phone: String = ""
    @Published var location: String = ""
    
    /// Optional remote avatar URL (if you ever add upload later)
    @Published var profileImageUrl: String = ""
    
    // MARK: - Preferences
    @Published var defaultCurrency: String = "CAD"
    @Published var timeZoneId: String = TimeZone.current.identifier
    @Published var languageCode: String = "en"
    
    // MARK: - Profile save state
    @Published var isSaving: Bool = false
    @Published var profileErrorMessage: String?
    @Published var profileSuccessMessage: String?
    
    // MARK: - Password fields / state
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmNewPassword: String = ""
    
    @Published var isChangingPassword: Bool = false
    @Published var passwordErrorMessage: String?
    @Published var passwordSuccessMessage: String?
    
    // MARK: - Delete account state
    @Published var isDeleting: Bool = false
    @Published var deleteErrorMessage: String?
    
    // Prevents loading profile multiple times
    private var hasLoadedProfile = false
    
    private var db: DatabaseReference {
        FirebaseManager.shared.database
    }
    
    // MARK: - Public: Load profile once when screen appears
    func refreshProfileIfNeeded() {
        guard !hasLoadedProfile else { return }
        hasLoadedProfile = true
        loadProfile()
    }
    
    // MARK: - Load profile from Realtime Database
    private func loadProfile() {
        guard let user = Auth.auth().currentUser else {
            self.profileErrorMessage = "You must be logged in to view your profile."
            return
        }
        
        // Start with auth fallback
        self.email = user.email ?? ""
        self.fullName = user.displayName ?? ""
        
        let ref = db.child("users").child(user.uid)
        
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            
            guard let data = snapshot.value as? [String: Any] else {
                // No user node yet → we'll create it on first save
                return
            }
            
            DispatchQueue.main.async {
                self.applyUserData(data, authUser: user)
            }
        }
    }
    
    // Apply dictionary from Realtime DB to @Published fields
    private func applyUserData(_ data: [String: Any], authUser: User) {
        if let name = data["fullName"] as? String {
            self.fullName = name
        } else if !authUser.displayName.orEmpty.isEmpty {
            self.fullName = authUser.displayName ?? ""
        }
        
        if let email = data["email"] as? String {
            self.email = email
        } else if let authEmail = authUser.email {
            self.email = authEmail
        }
        
        self.phone = data["phone"] as? String ?? ""
        self.location = data["location"] as? String ?? ""
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
        
        // Settings block: /users/{uid}/settings/...
        if let settings = data["settings"] as? [String: Any] {
            if let cur = settings["defaultCurrency"] as? String {
                self.defaultCurrency = cur
            }
            if let tz = settings["timeZoneId"] as? String {
                self.timeZoneId = tz
            }
            if let lang = settings["languageCode"] as? String {
                self.languageCode = lang
            }
        }
    }
    
    // MARK: - Save profile (name, phone, location, preferences)
    func saveProfile() {
        guard let user = Auth.auth().currentUser else {
            self.profileErrorMessage = "Not logged in."
            return
        }
        
        profileErrorMessage = nil
        profileSuccessMessage = nil
        isSaving = true
        
        let userRef = db.child("users").child(user.uid)
        
        // Flat profile fields
        var payload: [String: Any] = [
            "fullName": fullName,
            "email": email,
            "phone": phone,
            "location": location,
        ]
        
        // Nested settings
        let settings: [String: Any] = [
            "defaultCurrency": defaultCurrency,
            "timeZoneId": timeZoneId,
            "languageCode": languageCode
        ]
        payload["settings"] = settings
        
        userRef.updateChildValues(payload) { [weak self] error, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isSaving = false
                if let error = error {
                    self.profileErrorMessage = error.localizedDescription
                } else {
                    self.profileSuccessMessage = "Profile updated successfully."
                }
            }
        }
        
        // Also update FirebaseAuth displayName
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = fullName
        changeRequest.commitChanges { _ in
            // No UI feedback needed here; ignore errors for now
        }
    }
    
    // MARK: - Change Password
    func changePassword() {
        passwordErrorMessage = nil
        passwordSuccessMessage = nil
        
        guard !currentPassword.isEmpty,
              !newPassword.isEmpty,
              !confirmNewPassword.isEmpty else {
            passwordErrorMessage = "Please fill in all password fields."
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
        
        // 1) Re-authenticate with current password
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { [weak self] _, error in
            guard let self = self else { return }
            
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
    
    // MARK: - Delete Account
    /// Deletes user from Realtime DB and FirebaseAuth.
    /// Caller's responsibility: signOut + navigate away.
    func deleteAccount(completion: @escaping () -> Void) {
        deleteErrorMessage = nil
        isDeleting = true
        
        guard let user = Auth.auth().currentUser else {
            deleteErrorMessage = "Not logged in."
            isDeleting = false
            return
        }
        
        let uid = user.uid
        let userRef = db.child("users").child(uid)
        
        // 1) Remove from database
        userRef.removeValue { [weak self] error, _ in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isDeleting = false
                    self.deleteErrorMessage = "Failed to delete data: \(error.localizedDescription)"
                }
                return
            }
            
            // 2) Delete auth user
            user.delete { error in
                DispatchQueue.main.async {
                    self.isDeleting = false
                    if let error = error {
                        self.deleteErrorMessage = "Failed to delete account: \(error.localizedDescription)"
                    } else {
                        completion()
                    }
                }
            }
        }
    }
}

// Small helper so we can safely use `displayName.orEmpty`
private extension Optional where Wrapped == String {
    var orEmpty: String {
        self ?? ""
    }
}
