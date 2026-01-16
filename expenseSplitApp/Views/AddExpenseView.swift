//
//  AddExpenseView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-07.
//

import SwiftUI
import FirebaseAuth
import FirebaseDatabase   // ✅ Needed for DatabaseReference & child(...)

struct AddExpenseView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    
    // MARK: - Services
    private let groupService = GroupService()
    private let expenseService = ExpenseService()
    
    // MARK: - Data
    @State private var groups: [ExpenseGroup] = []
    @State private var memberNameMap: [String: String] = [:]   // userId -> full name/email
    
    // MARK: - Expense Form States
    @State private var selectedGroup: ExpenseGroup? = nil
    @State private var title: String = ""
    @State private var selectedCategory: String = "Uncategorized"
    @State private var selectedSubcategory: String? = nil
    @State private var amountText: String = ""
    @State private var paidByUserId: String = ""               // userId, not name
    @State private var splitMode: SplitMode = .equal
    @State private var percentageMap: [String: String] = [:]   // userId -> "percent text"
    @State private var date: Date = Date()
    @State private var place: String = ""
    @State private var note: String = ""
    @State private var selectedCurrency: String = "CAD"
    
    // MARK: - UI States
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isLoadingGroups: Bool = false
    @State private var isSaving: Bool = false
    
    enum SplitMode { case equal, percentage }
    
    // MARK: - Constants
    private let currencies = ["CAD","USD","EUR","INR","GBP"]
    private let categories: [String: [String]] = [
        "Entertainment": ["Game","Movie","Music","Sports","Other"],
        "Food & Drinks": ["Dining out","Groceries","Liquor","Other"],
        "Home": ["Electronics","Furniture","Household supplies","Maintenance"],
        "Transportation": ["Taxi","Ride share","Fuel","Other"],
        "Utilities": ["Electricity","Internet","Water","Other"],
        "Life": ["Health","Education","Gifts","Other"],
        "Travel": ["Flight","Hotel","Taxi","Other"],
        "Uncategorized": ["General"]
    ]
    
    // MARK: - Computed
    private var amountValue: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    
    private var membersForSelectedGroup: [String] {
        selectedGroup?.members ?? []
    }
    
    /// Returns the best label for a given userId, using loaded names first,
    /// then falling back to the current user's email/displayName, then UID.
    private func displayName(for userId: String) -> String {
        if let name = memberNameMap[userId], !name.isEmpty {
            if userId == authService.currentUserId {
                return "\(name) (You)"
            }
            return name
        }
        
        // Special-case: current user fallback from Firebase Auth
        if userId == authService.currentUserId {
            if let displayName = authService.firebaseUser?.displayName,
               !displayName.isEmpty {
                return "\(displayName) (You)"
            }
            if let email = authService.firebaseUser?.email,
               !email.isEmpty {
                return "\(email) (You)"
            }
        }
        
        // Last resort: raw UID
        return userId
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Add Expense")
                            .font(.largeTitle).bold()
                        Text("Record a new shared expense below.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // MARK: - Group / Person Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Who was this with?")
                            .font(.headline)
                        
                        if isLoadingGroups {
                            HStack {
                                ProgressView()
                                Text("Loading your groups...")
                                    .foregroundColor(.secondary)
                            }
                        } else if groups.isEmpty {
                            Text("You don't have any groups yet. Create a group first.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            HStack {
                                Text("With your group")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Menu {
                                    ForEach(groups, id: \.id) { group in
                                        Button(group.name) {
                                            selectedGroup = group
                                            // reset split and paidBy when changing group
                                            paidByUserId = defaultPaidBy(for: group)
                                            percentageMap = [:]
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedGroup?.name ?? "Select group")
                                        Image(systemName: "chevron.down")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .cardStyle()
                    
                    // MARK: - Description & Category
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Expense title (e.g. Dinner, Movie...)", text: $title)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories.keys.sorted(), id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        if let subs = categories[selectedCategory] {
                            Picker("Subcategory", selection: $selectedSubcategory) {
                                ForEach(subs, id: \.self) { s in Text(s).tag(Optional(s)) }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    .cardStyle()
                    
                    // MARK: - Amount & Currency
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Amount")
                            .font(.headline)
                        HStack {
                            TextField("0.00", text: $amountText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                            Picker("", selection: $selectedCurrency) {
                                ForEach(currencies, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 90)
                        }
                    }
                    .cardStyle()
                    
                    // MARK: - Paid By & Split
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Paid by & Split")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Paid by")
                                    .foregroundColor(.secondary)
                                Spacer()
                                
                                if !membersForSelectedGroup.isEmpty {
                                    Menu {
                                        ForEach(membersForSelectedGroup, id: \.self) { userId in
                                            Button(displayName(for: userId)) {
                                                paidByUserId = userId
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(paidByUserId.isEmpty ? "Select" : displayName(for: paidByUserId))
                                            Image(systemName: "chevron.down")
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                } else {
                                    Text("Select a group to choose who paid.")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                            
                            HStack {
                                Text("Shared")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { splitMode == .equal ? 0 : 1 },
                                    set: { splitMode = $0 == 0 ? .equal : .percentage }
                                )) {
                                    Text("Equally").tag(0)
                                    Text("By %").tag(1)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 200)
                            }
                            
                            if splitMode == .equal {
                                let participants = membersForSelectedGroup
                                if participants.isEmpty {
                                    Text("Select a group to split the expense.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    let count = participants.count
                                    let each = amountValue / Double(max(count, 1))
                                    Text("Split equally among \(count) people (\(String(format: "%.2f each", each)))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                if membersForSelectedGroup.isEmpty {
                                    Text("Select a group to assign percentages.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    ForEach(membersForSelectedGroup, id: \.self) { userId in
                                        HStack {
                                            Text(displayName(for: userId))
                                            Spacer()
                                            TextField("%", text: Binding(
                                                get: { percentageMap[userId] ?? "" },
                                                set: { percentageMap[userId] = $0 }
                                            ))
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 60)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .cardStyle()
                    
                    // MARK: - Details
                    VStack(alignment: .leading, spacing: 12) {
                        DatePicker("Date", selection: $date, displayedComponents: [.date])
                        TextField("Place (optional)", text: $place)
                            .textFieldStyle(.roundedBorder)
                        TextField("Note (optional)", text: $note)
                            .textFieldStyle(.roundedBorder)
                    }
                    .cardStyle()
                    
                    // MARK: - Save Button
                    Button {
                        Task { await saveTapped() }
                    } label: {
                        HStack {
                            if isSaving { ProgressView() }
                            Text("Save Expense")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                    .disabled(isSaving)
                }
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Expense"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .task {
                await loadGroups()
            }
            .toolbar {
                // 🔹 Cancel button like CreateGroupView
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func defaultPaidBy(for group: ExpenseGroup) -> String {
        if let currentId = authService.currentUserId,
           group.members.contains(currentId) {
            return currentId
        }
        return group.members.first ?? ""
    }
    
    // MARK: Load Groups from Firebase via GroupService
    @MainActor
    private func loadGroups() async {
        guard let userId = authService.currentUserId else {
            showError("You must be logged in to add an expense.")
            return
        }
        
        isLoadingGroups = true
        defer { isLoadingGroups = false }
        
        do {
            let fetchedGroups = try await groupService.fetchGroupsForUser(userId: userId)
            groups = fetchedGroups
            
            if selectedGroup == nil {
                selectedGroup = fetchedGroups.first
            }
            
            // Prepare member name map from all members in all groups
            let allMemberIds = Set(fetchedGroups.flatMap { $0.members })
            try await loadMemberNames(for: Array(allMemberIds))
            
            // Setup default paidBy if needed
            if let group = selectedGroup, paidByUserId.isEmpty {
                paidByUserId = defaultPaidBy(for: group)
            }
        } catch {
            showError("Failed to load groups: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Load names for userIds from /users
    /// Reads names directly from /users/{uid}, compatible with both "fullName" and legacy "name".
    private func loadMemberNames(for userIds: [String]) async throws {
        guard !userIds.isEmpty else { return }
        
        let db = FirebaseManager.shared.database
        var newMap: [String: String] = [:]
        
        for userId in userIds {
            do {
                let snapshot = try await db
                    .child("users")
                    .child(userId)
                    .getValueAsync()
                
                guard let data = snapshot.value as? [String: Any] else {
                    continue
                }
                
                // Try multiple field names for maximum compatibility
                var name: String?
                
                if let fullName = data["fullName"] as? String,
                   !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    name = fullName
                } else if let legacyName = data["name"] as? String,
                          !legacyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    name = legacyName
                } else if let email = data["email"] as? String,
                          !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    name = email
                }
                
                if let name = name {
                    newMap[userId] = name
                }
            } catch {
                // Ignore individual user failures and continue
                continue
            }
        }
        
        await MainActor.run {
            memberNameMap.merge(newMap) { _, new in new }
        }
    }
    
    // MARK: - Save Expense
    @MainActor
    private func saveTapped() async {
        guard authService.currentUserId != nil else {
            showError("You must be logged in to add an expense.")
            return
        }
        
        guard let group = selectedGroup else {
            showError("Please select a group.")
            return
        }
        
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError("Please enter a title.")
            return
        }
        guard amountValue > 0 else {
            showError("Enter a valid amount.")
            return
        }
        guard !membersForSelectedGroup.isEmpty else {
            showError("Selected group has no members.")
            return
        }
        
        // Ensure paidBy is set
        if paidByUserId.isEmpty {
            paidByUserId = defaultPaidBy(for: group)
        }
        
        // Build split dictionary: userId -> percentage
        let splitDict: [String: Int]
        
        if splitMode == .equal {
            let members = membersForSelectedGroup
            let count = members.count
            guard count > 0 else {
                showError("No participants for split.")
                return
            }
            let base = 100 / count
            let remainder = 100 - base * count
            
            var result: [String: Int] = [:]
            for (index, userId) in members.enumerated() {
                result[userId] = base + (index < remainder ? 1 : 0)
            }
            splitDict = result
            
        } else {
            let members = membersForSelectedGroup
            var result: [String: Int] = [:]
            var total = 0
            
            for userId in members {
                let pctString = percentageMap[userId] ?? "0"
                let pct = Int(pctString) ?? 0
                result[userId] = pct
                total += pct
            }
            
            guard total == 100 else {
                showError("Percentages must total exactly 100%. (Current: \(total)%)")
                return
            }
            
            splitDict = result
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            _ = try await expenseService.createExpense(
                groupId: group.id,
                title: title,
                amount: amountValue,
                paidBy: paidByUserId,
                date: date,
                category: selectedCategory,
                subcategory: selectedSubcategory,
                place: place.isEmpty ? nil : place,
                note: note.isEmpty ? nil : note,
                currency: selectedCurrency,
                split: splitDict
            )
            
            dismiss()
        } catch {
            showError("Failed to save expense: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}

// MARK: - View Modifiers
extension View {
    /// Adds a clean rounded background card look
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            .padding(.horizontal)
    }
}

// Preview
#Preview {
    AddExpenseView()
        .environmentObject(AuthService.shared)
}
