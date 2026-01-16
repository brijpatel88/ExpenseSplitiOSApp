//
//  CreateGroupView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-17.
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseStorage

/// Screen used to create a new expense group.
/// - Uploads cover image to Firebase Storage
/// - Saves group in Realtime DB via GroupService
struct CreateGroupView: View {
    
    // MARK: - Environment
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Services
    private let groupService = GroupService()
    
    // MARK: - Banner Image (local state)
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var bannerImageData: Data?        // local picked image
    @State private var uploadedImageURL: String?     // URL after upload
    
    // MARK: - Form Fields
    @State private var groupName: String = ""
    @State private var groupDescription: String = ""
    @State private var memberNote: String = ""
    
    enum DefaultSplitMode: String {
        case equal = "equal"
        case percentage = "percentage"
    }
    @State private var defaultSplitMode: DefaultSplitMode = .equal
    
    // MARK: - UI State
    @State private var isCreating: Bool = false
    @State private var isUploadingImage: Bool = false
    @State private var errorMessage: String?
    
    // MARK: - Validation
    private var canCreateGroup: Bool {
        let hasName = !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasName && !isCreating && !isUploadingImage && authService.currentUserId != nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // MARK: - Banner Image
                        bannerHeader
                            .padding(.top, 8)
                        
                        // MARK: - Main Form Card
                        ESCard {
                            VStack(alignment: .leading, spacing: 18) {
                                
                                if let error = errorMessage {
                                    Text(error)
                                        .foregroundColor(.red)
                                        .font(.footnote)
                                        .multilineTextAlignment(.center)
                                }
                                
                                groupDetailsSection
                                dividerLine
                                defaultSplitSection
                                dividerLine
                                membersInfoSection
                                
                                createButton
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 24)
                    }
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            // load picked photo data
            .onChange(of: selectedPhotoItem) { newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            self.bannerImageData = data
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Banner

private extension CreateGroupView {
    var bannerHeader: some View {
        ZStack(alignment: .bottomTrailing) {
            // Background banner
            Group {
                if let data = bannerImageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    // Default gradient banner
                    LinearGradient(
                        colors: [.esPrimary, .esMint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Text("New Group")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    )
                }
            }
            .frame(height: 190)
            .frame(maxWidth: .infinity)
            .clipped()
            .cornerRadius(26)
            .padding(.horizontal)
            .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
            
            // Change photo button
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                    Text("Change Photo")
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.55))
                .foregroundColor(.white)
                .cornerRadius(14)
                .padding(.trailing, 32)
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Sections

private extension CreateGroupView {
    
    var groupDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Group Details")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Group Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("e.g. Toronto Trip, Roommates, Office Lunch", text: $groupName)
                    .textInputAutocapitalization(.words)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Description (optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Add a short note about this group", text: $groupDescription, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }
        }
    }
    
    var defaultSplitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Default Split")
                .font(.headline)
            
            Text("This is the default way new expenses will be split in this group. You can still change it per expense.")
                .font(.footnote)
                .foregroundColor(.secondary)
            
            HStack(spacing: 0) {
                splitModeButton(title: "Equally", mode: .equal)
                splitModeButton(title: "By %", mode: .percentage)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
        }
    }
    
    func splitModeButton(title: String, mode: DefaultSplitMode) -> some View {
        Button {
            defaultSplitMode = mode
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(defaultSplitMode == mode ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if defaultSplitMode == mode {
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [.esPrimary, .esMint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                        } else {
                            Color.clear
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
    
    var membersInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Members")
                .font(.headline)
            
            Text("You (the creator) will be added automatically. You can invite or add more friends later from the group details screen.")
                .font(.footnote)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Members note (optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Add a note about members (optional)", text: $memberNote, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }
        }
    }
    
    var dividerLine: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: 1)
            .padding(.vertical, 4)
    }
    
    var createButton: some View {
        Button {
            Task { await createGroupTapped() }
        } label: {
            HStack(spacing: 8) {
                if isCreating || isUploadingImage {
                    ProgressView()
                        .tint(.white)
                }
                Text(isCreating || isUploadingImage ? "Creating..." : "Create Group")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canCreateGroup ? Color.esPrimary : Color.gray.opacity(0.4))
            .foregroundColor(.white)
            .cornerRadius(14)
            .shadow(color: canCreateGroup ? Color.esPrimary.opacity(0.35) : .clear,
                    radius: 10, y: 5)
        }
        .disabled(!canCreateGroup)
        .animation(.easeInOut(duration: 0.2), value: canCreateGroup)
    }
}

// MARK: - Actions

private extension CreateGroupView {
    
    private func createGroupTapped() async {
        guard let userId = authService.currentUserId else {
            errorMessage = "You must be logged in to create a group."
            return
        }
        
        guard canCreateGroup else {
            errorMessage = "Please enter a group name."
            return
        }
        
        errorMessage = nil
        isCreating = true
        
        do {
            // 1) Upload image if we picked one
            var imageUrl: String? = nil
            if let data = bannerImageData {
                isUploadingImage = true
                imageUrl = try await uploadGroupCoverImage(data: data, userId: userId)
                isUploadingImage = false
            }
            
            // 2) Create group in DB
            _ = try await groupService.createGroup(
                name: groupName.trimmingCharacters(in: .whitespacesAndNewlines),
                createdBy: userId,
                members: [userId],
                description: groupDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : groupDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                imageUrl: imageUrl
            )
            
            isCreating = false
            dismiss()
            
        } catch {
            isUploadingImage = false
            isCreating = false
            errorMessage = error.localizedDescription
            print("CreateGroup error:", error)   // helpful for debugging
        }
    }
    
    /// Uploads the selected banner image to Firebase Storage and returns its download URL.
    private func uploadGroupCoverImage(data: Data, userId: String) async throws -> String {
        let storage = Storage.storage()
        let rootRef = storage.reference()
        let fileId = UUID().uuidString
        
        let imageRef = rootRef
            .child("group_covers")
            .child(userId)
            .child("\(fileId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await imageRef.putDataAsync(data, metadata: metadata)
        let url = try await imageRef.downloadURLAsync()
        return url.absoluteString
    }
}

// MARK: - Async helpers for Firebase Storage

private extension StorageReference {
    
    /// Async wrapper for putData
    func putDataAsync(_ data: Data, metadata: StorageMetadata?) async throws -> StorageMetadata {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StorageMetadata, Error>) in
            self.putData(data, metadata: metadata) { meta, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: meta ?? StorageMetadata())
                }
            }
        }
    }
    
    /// Async wrapper for downloadURL()
    func downloadURLAsync() async throws -> URL {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            self.downloadURL { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "StorageReference.downloadURLAsync",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Missing download URL"]
                    ))
                }
            }
        }
    }
}
