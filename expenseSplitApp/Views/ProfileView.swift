//
//  ProfileView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-05.
//

import SwiftUI
import PhotosUI
import UIKit
import FirebaseAuth

struct ProfileView: View {
    
    // MARK: - Environment
    @EnvironmentObject var authService: AuthService
    
    // MARK: - ViewModel
    @StateObject private var vm = ProfileViewModel()
    
    // MARK: - Local avatar state
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea()
                
                if authService.currentUserId == nil {
                    notSignedInState
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // MARK: - Header
                            headerSection
                                .padding(.top, 12)
                            
                            // MARK: - Avatar Card (now full-width)
                            ESCard {
                                avatarSection
                            }
                            .padding(.horizontal, 20)
                            
                            // MARK: - Personal Info Only
                            ESCard {
                                basicInfoSection
                            }
                            .padding(.horizontal, 20)
                            
                            // MARK: - Save section
                            profileSaveSection
                                .padding(.horizontal, 20)
                            
                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { vm.refreshProfileIfNeeded() }
        .onChange(of: selectedPhotoItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run { self.selectedImageData = data }
                }
            }
        }
    }
}

private extension ProfileView {
    
    // MARK: - Not signed-in
    var notSignedInState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.exclam")
                .font(.system(size: 60))
                .foregroundColor(.esPrimary)
            
            Text("Not signed in")
                .font(.title2.bold())
            
            Text("Sign in to view and edit your profile.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }
    
    // MARK: - Header Section
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(vm.fullName.isEmpty ? "Profile" : vm.fullName)
                .font(.title.bold())
            
            if let uid = authService.currentUserId {
                Text("User ID: \(uid)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }
}

private extension ProfileView {
    
    // MARK: - Avatar Section (Wide)
    var avatarSection: some View {
        HStack {
            Spacer()
            
            ZStack {
                Circle()
                    .strokeBorder(
                        LinearGradient(colors: [.esPrimary, .esMint],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing),
                        lineWidth: 3
                    )
                    .frame(width: 90, height: 90)
                
                Circle()
                    .fill(Color("AvatarBackground"))
                    .frame(width: 82, height: 82)
                    .shadow(color: Color.black.opacity(0.15),
                            radius: 6, x: 0, y: 4)
                    .overlay(
                        avatarImage
                            .clipShape(Circle())
                    )
            }
            
            Spacer()
            
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label("Choose Photo", systemImage: "photo.on.rectangle")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.esPrimary.opacity(0.12))
                    .foregroundColor(.esPrimary)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    var avatarImage: some View {
        Group {
            if let data = selectedImageData,
               let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            }
            else if let url = URL(string: vm.profileImageUrl),
                    !vm.profileImageUrl.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty: ProgressView()
                    case .success(let image): image.resizable().scaledToFill()
                    default: defaultAvatarPlaceholder
                    }
                }
            } else {
                defaultAvatarPlaceholder
            }
        }
    }
    
    var defaultAvatarPlaceholder: some View {
        Image(systemName: "person.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 48, height: 48)
            .foregroundColor(Color("AvatarText"))
    }
}

private extension ProfileView {
    
    // MARK: - Basic Info (tight spacing)
    var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Info")
                .font(.headline)
            
            formField(title: "Full Name", binding: $vm.fullName)
            formField(title: "Email", binding: $vm.email, readOnly: true)
            formField(title: "Phone", binding: $vm.phone, keyboard: .phonePad)
            formField(title: "Location", binding: $vm.location)
        }
    }
    
    func formField(title: String,
                   binding: Binding<String>,
                   readOnly: Bool = false,
                   keyboard: UIKeyboardType = .default) -> some View {
        
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField(title, text: binding)
                .disabled(readOnly)
                .keyboardType(keyboard)
                .padding(10)
                .background(Color("CardBackground"))
                .cornerRadius(10)
                .opacity(readOnly ? 0.75 : 1)
        }
    }
}

private extension ProfileView {
    
    // MARK: - Save Section
    var profileSaveSection: some View {
        VStack(spacing: 8) {
            
            if let error = vm.profileErrorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            if let success = vm.profileSuccessMessage {
                Text(success)
                    .font(.footnote)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                vm.saveProfile()
            } label: {
                HStack {
                    if vm.isSaving {
                        ProgressView().tint(.white)
                    }
                    Text(vm.isSaving ? "Saving…" : "Save Profile")
                        .font(.headline)
                }
            }
            .buttonStyle(ESPrimaryButtonStyle())
            .disabled(vm.isSaving)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthService.shared)
    }
}
