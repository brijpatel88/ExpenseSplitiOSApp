//
//  HomeView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-12.
//
import SwiftUI

// MARK: - HomeView (Upgraded)
struct HomeView: View {
    // MARK: - State and services
    @State private var savedGroups: [ExpenseGroup] = []        // groups loaded from storage
    private let groupService = GroupService()           // persistence service
    
    // UI state
    @State private var query: String = ""               // search query
    @State private var selectedFilter: GroupFilter = .all
    @State private var showCreateGroup: Bool = false    // show create group sheet
    @State private var animateAppear: Bool = false     // small appear animation
    
    // MARK: - Computed / helper values
    private var filteredGroups: [ExpenseGroup] {
        var list = savedGroups
        
        // Filter by segmented control
        switch selectedFilter {
        case .all: break
        case .active:
            // Example placeholder: treat groups with members > 0 as active
            list = list.filter { $0.members.count > 0 }
        case .archived:
            // No archive flag currently on Group model — return empty for now
            list = []
        }
        
        // Search by name or description
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let lowercase = query.lowercased()
            list = list.filter {
                $0.name.lowercased().contains(lowercase) ||
                $0.description.lowercased().contains(lowercase)
            }
        }
        
        // Sort newest first (by dateCreated)
        list.sort { $0.dateCreated > $1.dateCreated }
        return list
    }
    
    // A simple total members count across saved groups
    private var totalMembers: Int {
        savedGroups.reduce(0) { $0 + $1.members.count }
    }
    
    // Placeholder total outstanding amount — you'll replace this when you add Expense model
    private var placeholderTotalAmount: String {
        // For now show 0.0 with currency of first group or default CAD
        let currency = savedGroups.first?.currency ?? "CAD"
        return "0.00 \(currency)"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color; use system grouped for a pleasant look
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // MARK: - Top Header / Summary
                    headerView
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .opacity(animateAppear ? 1 : 0)
                        .offset(y: animateAppear ? 0 : 10)
                        .animation(.easeOut(duration: 0.45), value: animateAppear)
                    
                    // MARK: - Search & Filter Row
                    VStack(spacing: 10) {
                        // Search field
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search groups or purpose", text: $query)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                            if !query.isEmpty {
                                Button(action: { query = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        
                        // Simple segmented filter
                        Picker("", selection: $selectedFilter) {
                            ForEach(GroupFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue.capitalized).tag(filter)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Content: Either groups list or empty state
                    if filteredGroups.isEmpty {
                        emptyStateView
                            .padding()
                            .transition(.opacity)
                    } else {
                        // List of group cards (scrollable)
                        ScrollView {
                            LazyVStack(spacing: 12, pinnedViews: []) {
                                ForEach(filteredGroups) { group in
                                    NavigationLink(destination: GroupDetailView(group: group)) {
                                        GroupCardView(group: group)
                                            .padding(.horizontal)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    Spacer(minLength: 10)
                } // VStack
                .onAppear {
                    // Load groups when screen appears
                    savedGroups = groupService.loadGroups()
                    // A small trigger to run appear animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
                        animateAppear = true
                    }
                }
                
                // MARK: - Floating Action Button (bottom-right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Menu {
                            // Menu actions under the FAB
                            Button(action: { showCreateGroup = true }) {
                                Label("Create Group", systemImage: "person.3.fill")
                            }
                            Button(action: {
                                // Placeholder: Add Expense flow (implement later)
                            }) {
                                Label("Add Expense", systemImage: "plus.circle")
                            }
                        } label: {
                            // Big blue circular FAB
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 64, height: 64)
                                    .shadow(radius: 6)
                                Image(systemName: "plus")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        // Present CreateGroupView sheet
                        .sheet(isPresented: $showCreateGroup, onDismiss: {
                            // Reload groups after creating a new one
                            savedGroups = groupService.loadGroups()
                        }) {
                            CreateGroupView()
                        }
                    }
                }
            } // ZStack
            .navigationTitle("My Groups")
            .navigationBarBackButtonHidden(true) // <-- Hides back button
        }
    }
    
    // MARK: - Top header view with summary cards
    private var headerView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome back!")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("Manage your groups & expenses")
                    .font(.subheadline)
                    .foregroundColor(.secondary.opacity(0.9))
            }
            Spacer()
            
            // Summary mini-card
            VStack(alignment: .trailing) {
                Text("\(savedGroups.count)")  // total groups
                    .font(.title)
                    .fontWeight(.bold)
                Text("Groups")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(.regularMaterial)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 4)
            
            // Another summary: total members (small)
            VStack(alignment: .trailing) {
                Text("\(totalMembers)")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Members")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(.regularMaterial)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 4)
        }
    }
    
    // MARK: - Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 18) {
            // Friendly graphic
            Image(systemName: "person.3.sequence")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
                .padding(.top, 8)
            
            Text("No groups yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create a group to start splitting expenses with friends. You'll see them here.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
            
            Button(action: { showCreateGroup = true }) {
                Label("Create your first group", systemImage: "person.3.fill")
                    .font(.headline)
                    .padding()
                    .frame(minWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
        }
    }
}

// MARK: - Group card component (reusable)
fileprivate struct GroupCardView: View {
    let group: ExpenseGroup
    
    var body: some View {
        HStack(spacing: 12) {
            // Group image or placeholder
            if let data = group.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                // Colored placeholder using a gradient derived from group id
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorForGroup(name: group.name))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Text(initials(from: group.name))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
            
            // Main info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(group.name)
                        .font(.headline)
                    Spacer()
                    // Small currency / placeholder amount on the right
                    Text("0.00 \(group.currency)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(group.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    // miniature avatars for first 3 members (placeholder circles)
                    ForEach(Array(group.members.prefix(3).enumerated()), id: \.offset) { idx, member in
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 22, height: 22)
                            .overlay(Text(String(member.prefix(1)).uppercased()).font(.caption).foregroundColor(.black))
                            .shadow(radius: 1)
                    }
                    
                    Text("\(group.members.count) members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Small chevron
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Helpers
    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].first!) + String(parts[1].first!)
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
    
    // Pick a color based on the group name (deterministic)
    private func colorForGroup(name: String) -> LinearGradient {
        let hash = abs(name.hashValue)
        let colorOptions = [
            Gradient(colors: [Color.blue, Color.purple]),
            Gradient(colors: [Color.green, Color.teal]),
            Gradient(colors: [Color.orange, Color.red]),
            Gradient(colors: [Color.pink, Color.indigo])
        ]
        let selection = colorOptions[hash % colorOptions.count]
        return LinearGradient(gradient: selection, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Small Enums / Models for UI
fileprivate enum GroupFilter: String, CaseIterable {
    case all, active, archived
}

// MARK: - Previews with sample data
struct HomeView_Previews: PreviewProvider {
    static var sampleGroups: [ExpenseGroup] {
        [
            ExpenseGroup(
                name: "Toronto Trip",
                description: "Weekend getaway expenses",
                currency: "CAD",
                dateCreated: Date().addingTimeInterval(-60*60*24*3),
                imageData: nil,
                members: ["Alice", "Bob", "Charlie"]
            ),
            ExpenseGroup(
                name: "Dinner Club",
                description: "Monthly dinner rotation",
                currency: "CAD",
                dateCreated: Date().addingTimeInterval(-60*60*24*7),
                imageData: nil,
                members: ["Sam", "Jess"]
            ),
            ExpenseGroup(
                name: "Office Gifts",
                description: "Team gift sharing",
                currency: "USD",
                dateCreated: Date().addingTimeInterval(-60*60*24*30),
                imageData: nil,
                members: []
            )
        ]
    }
    
    static var previews: some View {
        // Use a wrapper view to inject sample data for preview
        Group {
            HomeViewPreviewWrapper(groups: sampleGroups)
                .previewDisplayName("Home with Groups")
            
            HomeViewPreviewWrapper(groups: [])
                .previewDisplayName("Empty Home")
        }
    }
    
    // Small wrapper to inject preview data into HomeView
    struct HomeViewPreviewWrapper: View {
        let groups: [ExpenseGroup]
        var body: some View {
            HomeView()
                .onAppear {
                    // Directly write sample groups to UserDefaults using GroupService
                    GroupService().saveGroups(groups)
                }
        }
    }
}

