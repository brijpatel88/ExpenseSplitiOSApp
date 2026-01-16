//
//  FriendsView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-20.
//


import SwiftUI

struct FriendsView: View {
    
    // MARK: - Environment
    @EnvironmentObject var authService: AuthService
    
    // MARK: - Services
    private let friendService = FriendService()
    
    // MARK: - Tabs
    private enum FriendTab {
        case friends
        case requests
    }
    
    @State private var activeTab: FriendTab = .friends
    
    // MARK: - Data
    @State private var friends: [FriendModel] = []
    @State private var incomingRequests: [FriendRequestModel] = []
    
    // MARK: - UI State
    @State private var searchText: String = ""
    
    @State private var isLoadingFriends: Bool = false
    @State private var isLoadingRequests: Bool = false
    @State private var globalError: String?
    
    // Add Friend
    @State private var showAddFriendSheet: Bool = false
    @State private var newFriendEmail: String = ""
    @State private var isSendingRequest: Bool = false
    @State private var addFriendError: String?
    @State private var addFriendSuccess: String?
    
    // MARK: - Computed Filters
    
    private var filteredFriends: [FriendModel] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return friends
        }
        let lower = searchText.lowercased()
        return friends.filter { f in
            f.name.lowercased().contains(lower) ||
            f.email.lowercased().contains(lower)
        }
    }
    
    private var filteredRequests: [FriendRequestModel] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return incomingRequests
        }
        let lower = searchText.lowercased()
        return incomingRequests.filter { r in
            r.fromName.lowercased().contains(lower) ||
            r.email.lowercased().contains(lower)
        }
    }
    
    // Grid columns for cards
    private let gridColumns = [
        GridItem(.adaptive(minimum: 110, maximum: 160), spacing: 16)
    ]
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // Top header with tabs (WhatsApp style)
                    topHeader
                    
                    // Search bar
                    searchBar
                    
                    // Optional global error
                    if let globalError {
                        Text(globalError)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                    }
                    
                    // Content
                    contentSection
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Add friend button on the right
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        newFriendEmail = ""
                        addFriendError = nil
                        addFriendSuccess = nil
                        showAddFriendSheet = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.esPrimary)
                    }
                }
            }
            .task {
                await reloadAll()
            }
            .sheet(isPresented: $showAddFriendSheet) {
                addFriendSheet
            }
        }
    }
}

// MARK: - Top Header with Tabs (WhatsApp-style)

extension FriendsView {
    
    private var topHeader: some View {
        VStack(spacing: 10) {
            
            // Title row
            HStack {
                Text("Friends")
                    .font(.title2.bold())
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Tabs row
            HStack(spacing: 24) {
                tabButton(title: "Friends", tab: .friends, count: friends.count)
                tabButton(title: "Requests", tab: .requests, count: incomingRequests.count)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .background(Color("AppBackground"))
    }
    
    private func tabButton(title: String,
                           tab: FriendTab,
                           count: Int) -> some View {
        let isActive = (activeTab == tab)
        
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                activeTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline.weight(isActive ? .semibold : .regular))
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(isActive ? Color.esPrimary.opacity(0.15)
                                                   : Color.secondary.opacity(0.15))
                            )
                    }
                }
                .foregroundColor(isActive ? .esPrimary : .secondary)
                
                // Indicator line
                Rectangle()
                    .fill(
                        isActive ?
                        LinearGradient(
                            colors: [Color.esPrimary, Color.esMint],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Search Bar

extension FriendsView {
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(activeTab == .friends
                      ? "Search friends"
                      : "Search requests",
                      text: $searchText)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color("CardBackground"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Content Section

extension FriendsView {
    
    @ViewBuilder
    private var contentSection: some View {
        Group {
            switch activeTab {
            case .friends:
                friendsTabContent
            case .requests:
                requestsTabContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Friends list
    private var friendsTabContent: some View {
        Group {
            if isLoadingFriends && friends.isEmpty {
                ProgressView("Loading friends…")
                    .padding(.top, 40)
            } else if friends.isEmpty {
                emptyFriendsState
            } else if filteredFriends.isEmpty {
                noResultsState
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 18) {
                        ForEach(filteredFriends) { friend in
                            friendCard(friend)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    await reloadAll()
                }
            }
        }
    }
    
    // Requests list
    private var requestsTabContent: some View {
        Group {
            if isLoadingRequests && incomingRequests.isEmpty {
                ProgressView("Loading requests…")
                    .padding(.top, 40)
            } else if incomingRequests.isEmpty {
                emptyRequestsState
            } else if filteredRequests.isEmpty {
                noResultsState
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredRequests) { request in
                            requestRow(request)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    await reloadAll()
                }
            }
        }
    }
}

// MARK: - Friend Card

extension FriendsView {
    
    private func friendCard(_ friend: FriendModel) -> some View {
        ESCard {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.esPrimary, Color.esMint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .fill(Color("AvatarBackground"))
                        .frame(width: 62, height: 62)
                        .overlay(
                            Text(friend.initials)
                                .font(.headline)
                                .foregroundColor(Color("AvatarText"))
                        )
                }
                
                Text(friend.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if !friend.email.isEmpty {
                    Text(friend.email)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Request Row

extension FriendsView {
    
    private func requestRow(_ request: FriendRequestModel) -> some View {
        ESCard {
            HStack(spacing: 12) {
                
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.esPrimary, Color.esMint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(initials(for: request.fromName))
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    )
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.fromName)
                        .font(.subheadline.weight(.semibold))
                    if !request.email.isEmpty {
                        Text(request.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Actions
                VStack(spacing: 6) {
                    Button {
                        Task { await accept(request: request) }
                    } label: {
                        Text("Accept")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.esMint)
                    
                    Button(role: .destructive) {
                        Task { await reject(request: request) }
                    } label: {
                        Text("Reject")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
    
    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        if parts.isEmpty { return String(name.prefix(2)).uppercased() }
        return parts.map { String($0.first!).uppercased() }.joined()
    }
}

// MARK: - States: Empty / No results

extension FriendsView {
    
    private var emptyFriendsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .foregroundColor(.esPrimary)
                .shadow(radius: 6)
            
            Text("No friends yet")
                .font(.title2.bold())
            
            Text("Add your friends so you can quickly split expenses and keep track of who owes what.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                newFriendEmail = ""
                addFriendError = nil
                addFriendSuccess = nil
                showAddFriendSheet = true
            } label: {
                Label("Add your first friend", systemImage: "person.badge.plus")
                    .font(.headline)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.esPrimary)
        }
        .padding(.top, 40)
    }
    
    private var emptyRequestsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No friend requests")
                .font(.headline)
            Text("When someone adds you, requests will show up here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
    
    private var noResultsState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.title)
                .foregroundColor(.secondary)
            Text("No matches found")
                .font(.headline)
            Text("Try searching by a different name or email.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
}

// MARK: - Add Friend Sheet

extension FriendsView {
    
    private var addFriendSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                
                if let addFriendError {
                    Text(addFriendError)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }
                
                if let addFriendSuccess {
                    Text(addFriendSuccess)
                        .foregroundColor(.green)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Friend's Email")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("friend@example.com", text: $newFriendEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                Button {
                    Task { await sendFriendRequest() }
                } label: {
                    HStack {
                        if isSendingRequest {
                            ProgressView().tint(.white)
                        }
                        Text(isSendingRequest ? "Sending…" : "Send Request")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.esPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isSendingRequest || newFriendEmail.trimmingCharacters(in: .whitespaces).isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showAddFriendSheet = false }
                }
            }
        }
    }
}

// MARK: - Networking / Actions

extension FriendsView {
    
    private func reloadAll() async {
        guard let uid = authService.currentUserId else {
            await MainActor.run {
                globalError = "You must be signed in."
            }
            return
        }
        
        await MainActor.run {
            globalError = nil
        }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadFriends(for: uid) }
            group.addTask { await loadRequests(for: uid) }
        }
    }
    
    private func loadFriends(for uid: String) async {
        await MainActor.run { isLoadingFriends = true }
        
        // 🔥 NEW — Dummy mode override
            if DebugConfig.useDummyFriends {
                await MainActor.run {
                    friends = DummyFriendProvider.loadDummyFriends(count: DebugConfig.dummyFriendCount)
                    isLoadingFriends = false
                }
                return
            }
        
        // Real Firebase
        do {
            let fetched = try await friendService.fetchFriends(for: uid)
            await MainActor.run {
                friends = fetched
                isLoadingFriends = false
            }
        } catch {
            await MainActor.run {
                isLoadingFriends = false
                globalError = error.localizedDescription
            }
        }
    }
    
    private func loadRequests(for uid: String) async {
        await MainActor.run { isLoadingRequests = true }
        // 🔥 NEW — Dummy requests mode
            if DebugConfig.useDummyFriends {
                await MainActor.run {
                    incomingRequests = DummyFriendProvider.loadDummyRequests()
                    isLoadingRequests = false
                }
                return
            }

            // Real Firebase
        
        do {
            let fetched = try await friendService.fetchIncomingRequests(for: uid)
            await MainActor.run {
                incomingRequests = fetched
                isLoadingRequests = false
            }
        } catch {
            await MainActor.run {
                isLoadingRequests = false
                globalError = error.localizedDescription
            }
        }
    }
    
    private func sendFriendRequest() async {
        await MainActor.run {
            isSendingRequest = true
            addFriendError = nil
            addFriendSuccess = nil
        }
        
        do {
            try await friendService.sendFriendRequest(toEmail: newFriendEmail)
            await MainActor.run {
                isSendingRequest = false
                addFriendSuccess = "Friend request sent!"
                newFriendEmail = ""
            }
        } catch {
            await MainActor.run {
                isSendingRequest = false
                addFriendError = error.localizedDescription
            }
        }
    }
    
    private func accept(request: FriendRequestModel) async {
        guard let uid = authService.currentUserId else { return }
        do {
            try await friendService.acceptRequest(from: request.fromUserId, for: uid)
            await reloadAll()
        } catch {
            await MainActor.run {
                globalError = error.localizedDescription
            }
        }
    }
    
    private func reject(request: FriendRequestModel) async {
        guard let uid = authService.currentUserId else { return }
        do {
            try await friendService.rejectRequest(from: request.fromUserId, for: uid)
            await reloadAll()
        } catch {
            await MainActor.run {
                globalError = error.localizedDescription
            }
        }
    }
}







// MARK: - Preview

#Preview {
    NavigationStack {
        FriendsView()
            .environmentObject(AuthService.shared)
    }
}
