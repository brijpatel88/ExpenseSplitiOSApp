//
//  SettingsView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-05.
//

import SwiftUI
import FirebaseAuth

/// Main Settings screen styled with AppTheme + ESCard layout.
struct SettingsView: View {
    
    // MARK: - Environment
    @EnvironmentObject var authService: AuthService
    
    // MARK: - Stored Theme Preference
    @AppStorage("appTheme") private var appTheme: String = "system"
    
    // MARK: - Local UI State
    @State private var notificationsEnabled = true      // Local UI toggle (PreferencesView will store real value)
    @State private var useFaceID = false               // Local UI toggle (SecuritySettingsView will store real value)
    
    @State private var showSignOutAlert = false
    @State private var showDeleteAlert = false
    @State private var isDeletingAccount = false
    @State private var deleteErrorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // MARK: - Profile Card (ESCard, tap → ProfileView)
                profileCard
                
                // MARK: - Preferences (navigates to PreferencesView)
                ESCard {
                    sectionHeader("Preferences")
                    
                    NavigationLink {
                        PreferencesView()
                    } label: {
                        rowWithChevron(
                            label: "App Preferences",
                            icon: "slider.horizontal.3"
                        )
                    }
                }
                .padding(.horizontal)
                
                // MARK: - Security & Password (navigates to SecuritySettingsView)
                ESCard {
                    sectionHeader("Security & Password")
                    
                    NavigationLink {
                        SecuritySettingsView()
                    } label: {
                        rowWithChevron(
                            label: "Change Password & Face ID",
                            icon: "lock.shield"
                        )
                    }
                }
                .padding(.horizontal)
                
                // MARK: - App Info Section
                ESCard {
                    sectionHeader("App Info")
                    
                    VStack(spacing: 14) {
                        NavigationLink {
                            AboutView()
                        } label: {
                            rowWithChevron(
                                label: "About Expense Splitter",
                                icon: "info.circle"
                            )
                        }
                        
                        HStack {
                            Label("Version", systemImage: "number.circle")
                                .foregroundColor(.esPrimary)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                // MARK: - Sign Out Button
                ESCard {
                    Button {
                        showSignOutAlert = true
                    } label: {
                        Text("Sign Out")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal)
                .alert("Sign Out", isPresented: $showSignOutAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Sign Out", role: .destructive) {
                        authService.signOut()
                    }
                } message: {
                    Text("Are you sure you want to sign out?")
                }
                
                // MARK: - Danger Zone (FULL delete)
                ESCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Danger Zone")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        if let deleteErrorMessage {
                            Text(deleteErrorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                        
                        Text("Deleting your account will permanently remove your profile and data. This cannot be undone.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Button {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                if isDeletingAccount {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text(isDeletingAccount ? "Deleting…" : "Delete Account")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isDeletingAccount)
                    }
                }
                .padding(.horizontal)
                .alert("Delete Account?", isPresented: $showDeleteAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        deleteAccountTapped()
                    }
                } message: {
                    Text("This will permanently delete your account and profile data from FirebaseAuth and Realtime Database. This action cannot be undone.")
                }
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .background(Color("AppBackground").ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    // MARK: - Profile Card (Tap → ProfileView)
    private var profileCard: some View {
        NavigationLink(destination: ProfileView()) {
            ESCard {
                HStack(spacing: 16) {
                    
                    // Avatar with gradient ring (matches FriendsView)
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.esPrimary, .esMint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 76, height: 76)
                        
                        Circle()
                            .fill(Color("AvatarBackground"))
                            .frame(width: 68, height: 68)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(Color("AvatarText"))
                                    .font(.system(size: 28))
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authService.firebaseUser?.displayName ?? "My Profile")
                            .font(.headline)
                        
                        Text(authService.firebaseUser?.email ?? "Tap to edit profile")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    
    // MARK: - Section Header
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.bottom, 4)
    }
    
    // MARK: - Chevron Row (Reusable)
    private func rowWithChevron(label: String, icon: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundColor(.esPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
    }
    
    
    // MARK: - Delete Account Action
    private func deleteAccountTapped() {
        guard !isDeletingAccount else { return }
        deleteErrorMessage = nil
        isDeletingAccount = true
        
        DeleteAccountService.deleteCurrentUser { result in
            DispatchQueue.main.async {
                isDeletingAccount = false
                switch result {
                case .success:
                    // After successful delete, sign out so app returns to SignInView
                    authService.signOut()
                case .failure(let error):
                    deleteErrorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthService.shared)
    }
}
