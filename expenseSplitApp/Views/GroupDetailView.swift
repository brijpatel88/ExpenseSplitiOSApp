//
//  GroupDetailView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-05.
//


import SwiftUI
import FirebaseDatabase

struct GroupDetailView: View {
    
    // MARK: - Input
    let group: ExpenseGroup     // Passed from HomeView
    
    // MARK: - Environment
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    // Services
    private let expenseService = ExpenseService()
    private let friendService = FriendService()
    
    // MARK: - Tabs
    private enum DetailTab {
        case expenses
        case balances
        case reports
    }
    
    @State private var selectedTab: DetailTab = .expenses
    
    // MARK: - State: Expenses
    @State private var expenses: [Expense] = []
    @State private var isLoadingExpenses = false
    @State private var errorMessage: String?
    
    // MARK: - State: Members
    @State private var memberNameMap: [String: String] = [:]  // uid -> full name
    @State private var memberIds: [String] = []               // group members
    @State private var isLoadingMembers = false
    
    // MARK: - State: Friends (for Add Member)
    @State private var friends: [FriendModel] = []
    @State private var isLoadingFriends = false
    @State private var addMemberError: String?
    @State private var isAddingMember = false
    @State private var showAddMemberSheet = false
    
    // MARK: - Add Expense
    @State private var showAddExpense = false
    
    // MARK: - Delete expense
    @State private var showDeleteExpenseAlert = false
    @State private var expenseToDelete: Expense?
    
    // MARK: - Delete group
    @State private var showDeleteGroupAlert = false
    @State private var isDeletingGroup = false
    @State private var deleteGroupError: String?
    
    // MARK: - Settlement / Balances
    struct SettlementPair: Identifiable {
        let id = UUID()
        let fromName: String
        let toName: String
        let amount: Double
    }
    
    @State private var showSettlementSheet = false
    @State private var settlements: [SettlementPair] = []
    @State private var balances: [String: Double] = [:]   // uid -> net balance
    
    // MARK: - Computed helpers
    
    private var totalAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var currency: String {
        expenses.first?.currency ?? "CAD"
    }
    
    private var isCurrentUserAdmin: Bool {
        guard let currentId = authService.currentUserId else { return false }
        return currentId == group.createdBy
    }
    
    private func displayName(for userId: String) -> String {
        if let name = memberNameMap[userId] {
            return userId == authService.currentUserId ? "\(name) (You)" : name
        }
        return userId
    }
    
    // For Balance tab: current user’s own numbers
    private var currentUserBalance: Double {
        guard let uid = authService.currentUserId else { return 0 }
        return balances[uid] ?? 0
    }
    
    private var youOwe: Double {
        // Negative means you owe
        min(currentUserBalance, 0) * -1.0
    }
    
    private var youAreOwed: Double {
        max(currentUserBalance, 0)
    }
    
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color("AppBackground")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    
                    // Optional delete error at top
                    if let deleteError = deleteGroupError {
                        Text(deleteError)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    headerCard
                        .padding(.top, 8)
                    
                    tabsBar
                    
                    tabContent
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Floating + Add Expense button
            fabAddExpenseButton
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadEverything()
        }
        // Add Expense sheet
        .sheet(isPresented: $showAddExpense, onDismiss: {
            Task { await loadExpenses() }
        }) {
            AddExpenseView()
                .environmentObject(authService)
        }
        // Add Member sheet
        .sheet(isPresented: $showAddMemberSheet) {
            addMemberSheet
        }
        // Settlement sheet
        .sheet(isPresented: $showSettlementSheet) {
            settlementSheet
        }
        // Delete expense alert
        .alert("Delete Expense?",
               isPresented: $showDeleteExpenseAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deleteSelectedExpense() }
            }
        } message: {
            if let e = expenseToDelete {
                Text("Are you sure you want to delete \"\(e.title)\"?")
            } else {
                Text("Are you sure you want to delete this expense?")
            }
        }
        // Delete group confirmation
        .confirmationDialog(
            "Delete Group?",
            isPresented: $showDeleteGroupAlert,
            titleVisibility: .visible
        ) {
            Button(isDeletingGroup ? "Deleting…" : "Delete Group", role: .destructive) {
                Task { await deleteGroup() }
            }
            .disabled(isDeletingGroup)
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete this group and all its expenses permanently.")
        }
        // Top-right settings
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                settingsMenu
            }
        }
    }
}

// MARK: - Header Card

extension GroupDetailView {
    
    private var headerCard: some View {
        ESCard {
            VStack(alignment: .leading, spacing: 12) {
                
                // Image / banner
                if let urlString = group.imageUrl,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color(.secondarySystemBackground))
                                ProgressView()
                            }
                        case .success(let img):
                            img.resizable()
                                .scaledToFill()
                        default:
                            gradientPlaceholder
                        }
                    }
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    gradientPlaceholder
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                
                // Title + meta
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.name)
                        .font(.title2.bold())
                        .foregroundColor(.esTextPrimaryLight)
                    
                    if let desc = group.description, !desc.isEmpty {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        // Member count tappable → opens members tab
                        Button {
                            selectedTab = .balances // or keep on expenses; but tapping logically "members"
                        } label: {
                            Label("\(memberIds.count) members", systemImage: "person.3.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Label(group.createdAt.formatted(date: .abbreviated, time: .shortened),
                              systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var gradientPlaceholder: some View {
        LinearGradient(
            colors: [.esPrimary.opacity(0.9), .esMint.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Text(initials(of: group.name))
                .font(.largeTitle.bold())
                .foregroundColor(.white)
        )
    }
    
    private func initials(of name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].first ?? "X")\(parts[1].first ?? "X")".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Tabs Bar

extension GroupDetailView {
    
    private var tabsBar: some View {
        HStack(spacing: 8) {
            tabButton(title: "Expenses", icon: "list.bullet", tab: .expenses)
            tabButton(title: "Balance", icon: "person.2.circle", tab: .balances)
            tabButton(title: "Reports", icon: "chart.pie.fill", tab: .reports)
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
    
    private func tabButton(title: String, icon: String, tab: DetailTab) -> some View {
        let isSelected = (tab == selectedTab)
        
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.esPrimary.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.esPrimary : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .esPrimary : .secondary)
    }
}

// MARK: - Tab Content

extension GroupDetailView {
    
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case .expenses:
                expensesTab
            case .balances:
                balanceTab
            case .reports:
                reportsTab
            }
        }
        .animation(.easeInOut, value: selectedTab)
    }
}

// MARK: - Expenses Tab

extension GroupDetailView {
    
    private var expensesTab: some View {
        ESCard {
            VStack(alignment: .leading, spacing: 12) {
                
                HStack {
                    Text("Expenses")
                        .font(.headline)
                    Spacer()
                    if isLoadingExpenses {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
                
                if expenses.isEmpty && !isLoadingExpenses {
                    Text("No expenses yet.\nTap the + button to add one.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                } else {
                    VStack(spacing: 10) {
                        ForEach(expenses) { expense in
                            expenseRowMinimal(expense)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
    
    private func expenseRowMinimal(_ e: Expense) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(e.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.esTextPrimaryLight)
                
                Spacer()
                
                Text(String(format: "%.2f %@", e.amount, e.currency ?? currency))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.green)
            }
            
            HStack(spacing: 6) {
                Text("Paid by \(displayName(for: e.paidBy))")
                Text("•")
                Text(e.date.formatted(date: .abbreviated, time: .omitted))
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            if let cat = e.category {
                HStack(spacing: 6) {
                    Text(cat)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.10))
                        .cornerRadius(6)
                    
                    if let s = e.subcategory {
                        Text(s)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.mint.opacity(0.10))
                            .cornerRadius(6)
                    }
                }
            }
            
            HStack {
                Spacer()
                Button {
                    expenseToDelete = e
                    showDeleteExpenseAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
        }
    }
}

// MARK: - Balance Tab

extension GroupDetailView {
    
    private var balanceTab: some View {
        VStack(spacing: 12) {
            
            // Top summary card
            ESCard {
                VStack(spacing: 8) {
                    Text("Your Balance")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("You owe")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2f %@", youOwe, currency))
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("You are owed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2f %@", youAreOwed, currency))
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    let net = currentUserBalance
                    Text(net >= 0
                         ? "Net: you should receive \(String(format: "%.2f %@", net, currency))"
                         : "Net: you owe \(String(format: "%.2f %@", -net, currency))")
                    .font(.footnote)
                    .foregroundColor(net >= 0 ? .green : .red)
                }
            }
            .padding(.horizontal)
            
            // Per-member breakdown
            ESCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Per Member")
                        .font(.headline)
                    
                    if balances.isEmpty {
                        Text("No balances yet. Add some expenses.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(memberIds, id: \.self) { uid in
                            let bal = balances[uid] ?? 0
                            if abs(bal) < 0.01 {
                                HStack {
                                    Text(displayName(for: uid))
                                    Spacer()
                                    Text("Settled")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .font(.subheadline)
                            } else if bal > 0 {
                                HStack {
                                    Text(displayName(for: uid))
                                    Spacer()
                                    Text("should receive \(String(format: "%.2f %@", bal, currency))")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                .font(.subheadline)
                            } else {
                                HStack {
                                    Text(displayName(for: uid))
                                    Spacer()
                                    Text("owes \(String(format: "%.2f %@", -bal, currency))")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 4)
    }
}

// MARK: - Reports Tab

extension GroupDetailView {
    
    private var reportsTab: some View {
        VStack(spacing: 12) {
            ESCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Spending by Category")
                        .font(.headline)
                    
                    if totalAmount <= 0 {
                        Text("No data yet. Add expenses to see a breakdown.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        let breakdown = categoryBreakdown()
                        VStack(spacing: 12) {
                            ForEach(breakdown.keys.sorted(), id: \.self) { cat in
                                if let value = breakdown[cat] {
                                    let pct = value / totalAmount
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(cat)
                                                .font(.subheadline.weight(.semibold))
                                            Text(String(format: "%.1f%%", pct * 100))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(String(format: "%.2f %@", value, currency))
                                                .font(.subheadline)
                                            ProgressView(value: pct)
                                                .scaleEffect(x: 1, y: 0.7, anchor: .center)
                                        }
                                        .frame(width: 130)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 4)
    }
    
    private func categoryBreakdown() -> [String: Double] {
        var map: [String: Double] = [:]
        for e in expenses {
            let cat = e.category ?? "Uncategorized"
            map[cat, default: 0] += e.amount
        }
        return map
    }
}

// MARK: - Floating Add Expense Button

extension GroupDetailView {
    
    private var fabAddExpenseButton: some View {
        Button {
            showAddExpense = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [.esPrimary, .esMint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: .esPrimary.opacity(0.4), radius: 10, y: 6)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }
}

// MARK: - Settings Menu (top-right)

extension GroupDetailView {
    
    private var settingsMenu: some View {
        Menu {
            Button {
                addMemberError = nil
                showAddMemberSheet = true
            } label: {
                Label("Add member from friends", systemImage: "person.badge.plus")
            }
            
            Button {
                Task { await leaveGroup() }
            } label: {
                Label("Leave group", systemImage: "rectangle.portrait.and.arrow.right")
            }
            
            if isCurrentUserAdmin {
                Divider()
                Button(role: .destructive) {
                    deleteGroupError = nil
                    showDeleteGroupAlert = true
                } label: {
                    Label("Delete group", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.esPrimary)
        }
    }
}

// MARK: - Add Member Sheet (Friends only)

extension GroupDetailView {
    
    private var addMemberSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                
                if let err = addMemberError {
                    Text(err)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if isLoadingFriends {
                    ProgressView("Loading friends…")
                        .padding(.top, 20)
                    Spacer()
                } else {
                    //let availableFriends = friends.filter { !memberIds.contains($0.id) }
                    // TEMP: dummy friends for testing add-member sheet only
                    let testFriends: [FriendModel] = [
                        FriendModel(id: "d1", name: "Alex Dummy", email: "alex@test.com"),
                        FriendModel(id: "d2", name: "Priya Dummy", email: "priya@test.com"),
                        FriendModel(id: "d3", name: "Omar Dummy", email: "omar@test.com")
                    ]

                    let availableFriends = testFriends  // ← super simple
                    
                    if availableFriends.isEmpty {
                        VStack(spacing: 10) {
                            Text("No available friends")
                                .font(.headline)
                            Text("Either you have no friends yet, or all of your friends are already in this group.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 30)
                        Spacer()
                    } else {
                        List {
                            ForEach(availableFriends) { friend in
                                Button {
                                    Task { await addMember(friend: friend) }
                                } label: {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.esPrimary, .esMint],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 34, height: 34)
                                            .overlay(
                                                Text(friend.initials)
                                                    .font(.caption.bold())
                                                    .foregroundColor(.white)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(friend.name)
                                                .font(.subheadline.weight(.semibold))
                                            Text(friend.email)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if isAddingMember {
                                            ProgressView()
                                        } else {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(.esPrimary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showAddMemberSheet = false }
                }
            }
        }
    }
}

// MARK: - Settlement Sheet

extension GroupDetailView {
    
    private var settlementSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if settlements.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Everyone is settled!")
                            .font(.title2.bold())
                        Text("No remaining balances.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            ForEach(settlements) { item in
                                HStack(spacing: 14) {
                                    
                                    // FROM — owes
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.fromName)
                                            .font(.headline)
                                            .foregroundColor(.red)
                                        Text("owes")
                                            .font(.caption)
                                            .foregroundColor(.red.opacity(0.8))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(.blue)
                                    
                                    // TO — receives
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(item.toName)
                                            .font(.headline)
                                            .foregroundColor(.green)
                                        Text("receives")
                                            .font(.caption)
                                            .foregroundColor(.green.opacity(0.8))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    
                                    // Amount
                                    Text(String(format: "%.2f %@", item.amount, currency))
                                        .font(.headline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.green.opacity(0.15))
                                        .cornerRadius(10)
                                        .foregroundColor(.green)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Settle Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showSettlementSheet = false }
                }
            }
        }
    }
}

// MARK: - Load Data

extension GroupDetailView {
    
    private func loadEverything() async {
        await MainActor.run {
            memberIds = group.members
        }
        
        await withTaskGroup(of: Void.self) { tg in
            tg.addTask { await loadExpenses() }
            tg.addTask { await loadMembers() }
            tg.addTask { await loadFriends() }
        }
        
        // After first load, compute balances + settlements
        await MainActor.run {
            recomputeBalancesAndSettlements()
        }
    }
    
    @MainActor
    private func loadExpenses() async {
        guard authService.currentUserId != nil else { return }
        isLoadingExpenses = true
        errorMessage = nil
        
        do {
            expenses = try await expenseService.fetchExpenses(forGroup: group.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoadingExpenses = false
        recomputeBalancesAndSettlements()
    }
    
    private func loadMembers() async {
        await MainActor.run { isLoadingMembers = true }
        
        var map: [String: String] = [:]
        
        for uid in group.members {
            do {
                let snap = try await FirebaseManager.shared.database
                    .child("users")
                    .child(uid)
                    .getValueAsync()
                
                if let data = snap.value as? [String: Any],
                   let u = UserModel(id: uid, data: data) {
                    map[uid] = u.fullName
                }
            } catch { }
        }
        
        await MainActor.run {
            memberNameMap = map
            isLoadingMembers = false
        }
    }
    
    private func loadFriends() async {
        guard let uid = authService.currentUserId else { return }
        await MainActor.run { isLoadingFriends = true }
        
        do {
            let list = try await friendService.fetchFriends(for: uid)
            await MainActor.run {
                friends = list
                isLoadingFriends = false
            }
        } catch {
            await MainActor.run {
                isLoadingFriends = false
                // silently ignore; friend tab still works, this only affects add-member sheet
            }
        }
    }
}

// MARK: - Actions

extension GroupDetailView {
    
    private func deleteSelectedExpense() async {
        guard let expense = expenseToDelete else { return }
        
        do {
            try await expenseService.deleteExpense(expenseId: expense.id)
            await loadExpenses()
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
        
        await MainActor.run { expenseToDelete = nil }
    }
    
    private func deleteGroup() async {
        guard let currentId = authService.currentUserId else { return }
        
        // Admin-only delete
        guard currentId == group.createdBy else {
            await MainActor.run {
                deleteGroupError = "Only the group owner can delete this group."
            }
            return
        }
        
        await MainActor.run {
            isDeletingGroup = true
            deleteGroupError = nil
        }
        
        let db = FirebaseManager.shared.database
        
        do {
            // Delete all expenses + splits for this group
            let expSnap = try await db.child("expenses").getValueAsync()
            for child in expSnap.children.allObjects as? [DataSnapshot] ?? [] {
                guard
                    let data = child.value as? [String: Any],
                    let gid = data["groupId"] as? String,
                    gid == group.id
                else { continue }
                
                try await db.child("expenses").child(child.key).removeValueAsync()
                try await db.child("expense_splits").child(child.key).removeValueAsync()
            }
            
            // Delete group & membership
            try await db.child("groups").child(group.id).removeValueAsync()
            try await db.child("group_members").child(group.id).removeValueAsync()
            
            await MainActor.run {
                isDeletingGroup = false
                dismiss()
            }
            
        } catch {
            await MainActor.run {
                isDeletingGroup = false
                deleteGroupError = error.localizedDescription
            }
        }
    }
    
    private func addMember(friend: FriendModel) async {
        await MainActor.run {
            isAddingMember = true
            addMemberError = nil
        }
        
        let uid = friend.id
        let db = FirebaseManager.shared.database
        
        do {
            // Update DB: /groups/{id}/members/{uid} = true
            try await db
                .child("groups")
                .child(group.id)
                .child("members")
                .child(uid)
                .setValueAsync(true)
            
            // Update DB: /group_members/{groupId}/{uid} = true
            try await db
                .child("group_members")
                .child(group.id)
                .child(uid)
                .setValueAsync(true)
            
            await MainActor.run {
                if !memberIds.contains(uid) {
                    memberIds.append(uid)
                }
                memberNameMap[uid] = friend.name
                isAddingMember = false
                showAddMemberSheet = false
            }
            
        } catch {
            await MainActor.run {
                isAddingMember = false
                addMemberError = error.localizedDescription
            }
        }
    }
    
    private func leaveGroup() async {
        guard let currentId = authService.currentUserId else { return }
        
        let db = FirebaseManager.shared.database
        
        // If current user is admin, transfer admin to another member if possible
        if currentId == group.createdBy {
            let others = memberIds.filter { $0 != currentId }
            if let newAdmin = others.randomElement() {
                do {
                    try await db
                        .child("groups")
                        .child(group.id)
                        .child("createdBy")
                        .setValueAsync(newAdmin)
                } catch {
                    await MainActor.run {
                        deleteGroupError = "Failed to transfer admin before leaving: \(error.localizedDescription)"
                    }
                    return
                }
            } else {
                // Only member → just delete group entirely
                await deleteGroup()
                return
            }
        }
        
        // Remove membership
        do {
            try await db
                .child("groups")
                .child(group.id)
                .child("members")
                .child(currentId)
                .removeValueAsync()
            
            try await db
                .child("group_members")
                .child(group.id)
                .child(currentId)
                .removeValueAsync()
            
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                deleteGroupError = "Failed to leave group: \(error.localizedDescription)"
            }
        }
    }
    
    private func recomputeBalancesAndSettlements() {
        // balances[uid] > 0 => should receive
        // balances[uid] < 0 => owes
        
        var newBalances: [String: Double] = [:]
        
        for e in expenses {
            let total = e.amount
            let splits = e.split   // [String: Int] percentage
            
            guard !splits.isEmpty else { continue }
            
            // Everyone owes their share
            for (uid, pct) in splits {
                let share = total * (Double(pct) / 100.0)
                newBalances[uid, default: 0] -= share
            }
            
            // Payer paid full amount
            newBalances[e.paidBy, default: 0] += total
        }
        
        balances = newBalances
        
        // Now compute settlement pairs (same greedy algorithm as before)
        var debtors: [(uid: String, amt: Double)] = []
        var creditors: [(uid: String, amt: Double)] = []
        
        for (uid, bal) in newBalances {
            if bal > 0.01 {
                creditors.append((uid, bal))
            } else if bal < -0.01 {
                debtors.append((uid, -bal))
            }
        }
        
        creditors.sort { $0.amt > $1.amt }
        debtors.sort { $0.amt > $1.amt }
        
        var results: [SettlementPair] = []
        var i = 0
        var j = 0
        
        while i < debtors.count && j < creditors.count {
            let pay = min(debtors[i].amt, creditors[j].amt)
            
            if pay > 0.01 {
                results.append(
                    SettlementPair(
                        fromName: displayName(for: debtors[i].uid),
                        toName: displayName(for: creditors[j].uid),
                        amount: pay
                    )
                )
            }
            
            debtors[i].amt -= pay
            creditors[j].amt -= pay
            
            if debtors[i].amt <= 0.01 { i += 1 }
            if creditors[j].amt <= 0.01 { j += 1 }
        }
        
        settlements = results
    }
}
