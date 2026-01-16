//
//  HomeView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-12.
//

import SwiftUI

struct HomeView: View {
    
    // MARK: - Environment
    @EnvironmentObject var authService: AuthService
    private let groupService = GroupService()
    
    // MARK: - State
    @State private var groups: [ExpenseGroup] = []
    @State private var query: String = ""
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    @State private var showCreateGroup: Bool = false
    @State private var showAddExpense: Bool = false
    
    // MARK: - Filter
    private var filteredGroups: [ExpenseGroup] {
        let trimmed = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return groups }
        
        return groups.filter { group in
            group.name.lowercased().contains(trimmed) ||
            (group.description ?? "").lowercased().contains(trimmed)
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    headerCard
                    
                    searchBar
                        .padding(.horizontal)
                        .padding(.top, 12)
                    
                    contentSection
                }
                
                fabButton
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadGroups() }
        }
    }
    
    
    // MARK: - HEADER CARD
    private var headerCard: some View {
        ESCard {
            VStack(alignment: .leading, spacing: 10) {
                
                Text("Welcome back 👋")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Your Groups")
                    .font(.largeTitle.bold())
                    .foregroundColor(.esPrimary)
                
                HStack(spacing: 16) {
                    statBox(
                        value: groups.count,
                        label: "Groups"
                    )
                    
                    let membersTotal = groups.reduce(0) { $0 + $1.members.count }
                    statBox(
                        value: membersTotal,
                        label: "Members"
                    )
                }
                .padding(.top, 6)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
    
    
    // MARK: - STAT BOX
    private func statBox(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.bold())
                .foregroundColor(.esPrimary)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .esPrimary.opacity(0.12), radius: 8, y: 5)
        )
    }
    
    
    // MARK: - SEARCH BAR
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.esPrimary)
            
            TextField("Search groups", text: $query)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.esPrimary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .esPrimary.opacity(0.10), radius: 8, y: 4)
        )
    }
    
    
    // MARK: - CONTENT
    private var contentSection: some View {
        Group {
            if isLoading {
                ProgressView("Loading groups…")
                    .padding(.top, 40)
            }
            else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        Task { await loadGroups() }
                    }
                    .buttonStyle(ESPrimaryButtonStyle())
                }
                .padding(.top, 30)
            }
            else if filteredGroups.isEmpty {
                emptyState
            }
            else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(filteredGroups) { group in
                            NavigationLink {
                                GroupDetailView(group: group)
                            } label: {
                                GroupRow(group: group)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    
    // MARK: - EMPTY STATE
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 80))
                .foregroundColor(.esPrimary)
                .padding(.top, 20)
            
            Text("No Groups Yet")
                .font(.title2.bold())
            
            Text("Start by creating a group to split expenses with your friends.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showCreateGroup = true
            } label: {
                Text("Create Group")
                    .font(.headline)
            }
            .buttonStyle(ESPrimaryButtonStyle())
        }
        .padding(.top, 40)
    }
    
    
    // MARK: - FAB BUTTON
    private var fabButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Menu {
                    Button {
                        showCreateGroup = true
                    } label: {
                        Label("Create Group", systemImage: "person.3.fill")
                    }
                    
                    Button {
                        showAddExpense = true
                    } label: {
                        Label("Add Expense", systemImage: "plus.circle")
                    }
                    
                } label: {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.esPrimary, .esMint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 62, height: 62)
                        .shadow(color: .esPrimary.opacity(0.4), radius: 12, y: 6)
                        .overlay(
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .font(.title2.bold())
                        )
                }
                .padding()
            }
        }
        .sheet(isPresented: $showCreateGroup) {
            CreateGroupView()
                .environmentObject(authService)
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView()
                .environmentObject(authService)
        }
    }
    
    
    // MARK: - LOAD GROUPS
    @MainActor
    private func loadGroups() async {
        guard let userId = authService.currentUserId else {
            errorMessage = "You must be logged in."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            groups = try await groupService.fetchGroupsForUser(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}


// MARK: - GROUP ROW (Themed w/ ESCard)
struct GroupRow: View {
    let group: ExpenseGroup
    
    var body: some View {
        ESCard {
            HStack(spacing: 14) {
                
                GroupImage
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .esPrimary.opacity(0.25), radius: 8, y: 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.name)
                        .font(.headline)
                        .foregroundColor(.esTextPrimaryLight)
                    
                    if let desc = group.description, !desc.isEmpty {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Text("\(group.members.count) members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Group Image
    private var GroupImage: some View {
        Group {
            if let url = URL(string: group.imageUrl ?? "") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
    }
    
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [.esPrimary, .esMint],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Text(String(group.name.prefix(2)).uppercased())
                    .font(.title2.bold())
                    .foregroundColor(.white)
            )
    }
}
