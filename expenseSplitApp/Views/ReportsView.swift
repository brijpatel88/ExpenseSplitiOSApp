//
//  ReportsView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-05.
//

import SwiftUI
import FirebaseAuth

/// Reports screen showing spending summary, categories, and insights.
/// Now includes:
/// - Group filter (all groups or specific group)
/// - Date range filter (all time, this month, last month, etc.)
/// - Filter sheet with Apply / Reset
struct ReportsView: View {
    
    // MARK: - Environment
    @EnvironmentObject var authService: AuthService
    
    // MARK: - Services
    private let groupService = GroupService()
    private let expenseService = ExpenseService()
    
    // MARK: - Data
    @State private var groups: [ExpenseGroup] = []
    @State private var allExpenses: [Expense] = []
    
    @State private var categoryTotals: [String: Double] = [:]
    
    @State private var totalSpent: Double = 0
    @State private var youOwe: Double = 0
    @State private var owedToYou: Double = 0
    
    // MARK: - Filters
    
    /// Group filter: nil = all groups
    @State private var selectedGroupId: String? = nil
    
    /// Date range filter preset
    @State private var selectedDateRange: DateRangePreset = .allTime
    
    /// Custom date range (used only when selectedDateRange == .custom)
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate: Date = Date()
    
    /// Controls the filter sheet
    @State private var showFilterSheet = false
    
    // MARK: - UI State
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var animate = false
    
    // MARK: - Date Range Preset
    enum DateRangePreset: String, CaseIterable, Identifiable {
        case allTime
        case thisMonth
        case lastMonth
        case last3Months
        case last6Months
        case thisYear
        case custom
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .allTime:    return "All time"
            case .thisMonth:  return "This month"
            case .lastMonth:  return "Last month"
            case .last3Months:return "Last 3 months"
            case .last6Months:return "Last 6 months"
            case .thisYear:   return "This year"
            case .custom:     return "Custom range"
            }
        }
    }
    
    // MARK: - Derived
    
    /// All expenses after applying group + date filters
    private var filteredExpenses: [Expense] {
        var result = allExpenses
        
        // 1) Filter by group
        if let gid = selectedGroupId {
            result = result.filter { $0.groupId == gid }
        }
        
        // 2) Filter by date range
        guard let range = currentDateRange else {
            // .allTime
            return result
        }
        
        return result.filter { exp in
            exp.date >= range.start && exp.date < range.end
        }
    }
    
    /// Current date range (start/end, end is treated as exclusive upper bound)
    private var currentDateRange: (start: Date, end: Date)? {
        let cal = Calendar.current
        let now = Date()
        
        switch selectedDateRange {
        case .allTime:
            return nil
            
        case .thisMonth:
            guard let start = cal.date(from: cal.dateComponents([.year, .month], from: now)),
                  let end = cal.date(byAdding: .month, value: 1, to: start) else { return nil }
            return (start, end)
            
        case .lastMonth:
            guard let thisMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)),
                  let start = cal.date(byAdding: .month, value: -1, to: thisMonthStart) else { return nil }
            let end = thisMonthStart
            return (start, end)
            
        case .last3Months:
            guard let start = cal.date(byAdding: .month, value: -3, to: now),
                  let end = cal.date(byAdding: .day, value: 1, to: now) else { return nil }
            return (start, end)
            
        case .last6Months:
            guard let start = cal.date(byAdding: .month, value: -6, to: now),
                  let end = cal.date(byAdding: .day, value: 1, to: now) else { return nil }
            return (start, end)
            
        case .thisYear:
            let comps = cal.dateComponents([.year], from: now)
            guard let start = cal.date(from: comps),
                  let end = cal.date(byAdding: .year, value: 1, to: start) else { return nil }
            return (start, end)
            
        case .custom:
            let start = min(customStartDate, customEndDate)
            // Add 1 day to the end to make it inclusive
            let end = cal.date(byAdding: .day, value: 1, to: max(customStartDate, customEndDate)) ?? max(customStartDate, customEndDate)
            return (start, end)
        }
    }
    
    private var hasAnyExpenses: Bool {
        !allExpenses.isEmpty
    }
    
    private var hasFilteredExpenses: Bool {
        !filteredExpenses.isEmpty
    }
    
    private var hasFiltersApplied: Bool {
        selectedGroupId != nil || selectedDateRange != .allTime
    }
    
    /// Text like "All groups • All time" or "Toronto Trip • Last 3 months"
    private var filterSummaryText: String {
        let groupText: String
        if let gid = selectedGroupId,
           let g = groups.first(where: { $0.id == gid }) {
            groupText = g.name
        } else {
            groupText = "All groups"
        }
        
        let dateText: String = selectedDateRange.title
        return "\(groupText) • \(dateText)"
    }
    
    // MARK: - BODY
    var body: some View {
        ZStack {
            
            // MARK: - THEME BACKGROUND (Same as HomeView / FriendsView)
            Color("AppBackground")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 26) {
                    
                    // MARK: Header + Filters summary + button
                    headerSection
                    
                    // MARK: ESCard Container
                    ESCard {
                        VStack(spacing: 24) {
                            
                            if isLoading {
                                loadingState
                            }
                            else if let error = errorMessage {
                                errorState(error)
                            }
                            else if !hasAnyExpenses {
                                // No expenses at all in any group
                                emptyState
                            }
                            else if !hasFilteredExpenses {
                                // There is data, but not matching current filters
                                filteredEmptyState
                            }
                            else {
                                summarySection
                                categorySection
                                comingSoonSection
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { animate = true }
        .task { await loadReports() }
        .sheet(isPresented: $showFilterSheet) {
            filterSheet
        }
        // Recompute metrics whenever filters or raw data change
        .onChange(of: selectedGroupId) { _ in
            recomputeForCurrentFilters()
        }
        .onChange(of: selectedDateRange) { _ in
            recomputeForCurrentFilters()
        }
        .onChange(of: customStartDate) { _ in
            if selectedDateRange == .custom {
                recomputeForCurrentFilters()
            }
        }
        .onChange(of: customEndDate) { _ in
            if selectedDateRange == .custom {
                recomputeForCurrentFilters()
            }
        }
        .onChange(of: allExpenses) { _ in
            recomputeForCurrentFilters()
        }
    }
}

//
// MARK: - HEADER
//
private extension ReportsView {
    
    /// Animated header showing title, logged-in email, and filter summary + button
    var headerSection: some View {
        VStack(spacing: 10) {
            
            // Title + subtitle
            VStack(spacing: 6) {
                Text("Reports")
                    .font(.largeTitle.bold())
                    .foregroundColor(.esPrimary)
                
                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Filters summary + button
            HStack(spacing: 10) {
                
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.caption)
                        .foregroundColor(.esPrimary)
                    Text(filterSummaryText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemBackground).opacity(0.95))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                
                Spacer()
                
                Button {
                    showFilterSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Filters")
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.esPrimary)
                .controlSize(.small)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .padding(.top, 20)
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 10)
        .animation(.easeOut(duration: 0.35), value: animate)
    }
    
    /// Subtitle showing logged-in email
    var subtitleText: String {
        if let email = authService.firebaseUser?.email {
            return "Summary for \(email)"
        }
        return "Your expense insights"
    }
}

//
// MARK: - STATES: Loading, Error, Empty
//
private extension ReportsView {
    
    /// Loading spinner + text
    var loadingState: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Loading your reports…")
                .foregroundColor(.secondary)
                .font(.footnote)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    /// Error display
    func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Couldn't load reports")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task { await loadReports() }
            }
            .buttonStyle(ESPrimaryButtonStyle())
        }
        .padding(.vertical, 40)
    }
    
    /// Empty view when no expenses in any group
    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 56))
                .foregroundColor(.esPrimary)
            
            Text("No data to report")
                .font(.title3.bold())
            
            Text("Add expenses in any group to see your spending insights.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 40)
    }
    
    /// State when there IS data overall, but nothing matches the current filters
    var filteredEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.title)
                .foregroundColor(.secondary)
            
            Text("No results for these filters")
                .font(.headline)
            
            Text("Try changing the group or date range to see your reports.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            if hasFiltersApplied {
                Button("Clear filters") {
                    resetFilters()
                }
                .buttonStyle(ESPrimaryButtonStyle())
            }
        }
        .padding(.vertical, 40)
    }
}

//
// MARK: - SUMMARY CARDS
//
private extension ReportsView {
    
    /// Summary grid (Total Spent, Groups, You Owe, Owed To You)
    var summarySection: some View {
        VStack(spacing: 16) {
            
            HStack(spacing: 16) {
                summaryCard(
                    icon: "dollarsign.circle.fill",
                    iconColor: .esPrimary,
                    title: "Total Spent",
                    value: formatCurrency(totalSpent)
                )
                
                summaryCard(
                    icon: "person.3.fill",
                    iconColor: .esMint,
                    title: "Groups",
                    value: groupsCountText
                )
            }
            
            HStack(spacing: 16) {
                summaryCard(
                    icon: "arrow.up.circle.fill",
                    iconColor: .orange,
                    title: "You Owe",
                    value: formatCurrency(youOwe)
                )
                
                summaryCard(
                    icon: "arrow.down.circle.fill",
                    iconColor: .green,
                    title: "Owed to You",
                    value: formatCurrency(owedToYou)
                )
            }
        }
    }
    
    /// Reusable summary card UI
    func summaryCard(icon: String, iconColor: Color, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(iconColor)
                .padding(10)
                .background(iconColor.opacity(0.12))
                .clipShape(Circle())
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity)
    }
    
    /// Shows count of groups, respecting group filter
    var groupsCountText: String {
        if let gid = selectedGroupId,
           let _ = groups.first(where: { $0.id == gid }) {
            return "1"
        }
        return "\(groups.count)"
    }
}

//
// MARK: - CATEGORY SECTION
//
private extension ReportsView {
    
    /// Category totals list
    var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("By Category")
                .font(.headline)
            
            if categoryTotals.isEmpty {
                Text("No categorized expenses for this filter.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            else {
                VStack(spacing: 8) {
                    ForEach(sortedCategoryTotals(), id: \.0) { category, amount in
                        HStack {
                            Text(category)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(formatCurrency(amount))
                                .font(.subheadline.bold())
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

//
// MARK: - COMING SOON
//
private extension ReportsView {
    
    var comingSoonSection: some View {
        VStack(spacing: 8) {
            Text("More insights coming soon")
                .font(.headline)
            
            Text("• Monthly spending\n• Category charts\n• Group balances\n• Trends over time")
                .foregroundColor(.secondary)
                .font(.footnote)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }
}

//
// MARK: - FILTER SHEET
//
private extension ReportsView {
    
    var filterSheet: some View {
        NavigationStack {
            Form {
                Section("Group") {
                    Picker("Group", selection: $selectedGroupId) {
                        Text("All groups").tag(String?.none)
                        ForEach(groups) { g in
                            Text(g.name).tag(String?.some(g.id))
                        }
                    }
                }
                
                Section("Date range") {
                    Picker("Date range", selection: $selectedDateRange) {
                        ForEach(DateRangePreset.allCases) { preset in
                            Text(preset.title).tag(preset)
                        }
                    }
                    
                    if selectedDateRange == .custom {
                        DatePicker("From",
                                   selection: $customStartDate,
                                   displayedComponents: .date)
                        DatePicker("To",
                                   selection: $customEndDate,
                                   displayedComponents: .date)
                    }
                }
                
                if hasFiltersApplied {
                    Section {
                        Button("Clear filters", role: .destructive) {
                            resetFilters()
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showFilterSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        showFilterSheet = false
                        recomputeForCurrentFilters()
                    }
                }
            }
        }
    }
    
    func resetFilters() {
        selectedGroupId = nil
        selectedDateRange = .allTime
    }
}

//
// MARK: - DATA LOADING & METRICS
//
private extension ReportsView {
    
    /// Fetches groups + expenses and computes summary data
    @MainActor
    func loadReports() async {
        guard let userId = authService.currentUserId else {
            errorMessage = "You must be logged in."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Load groups
            let fetchedGroups = try await groupService.fetchGroupsForUser(userId: userId)
            groups = fetchedGroups
            
            // Load all expenses from all groups
            var all: [Expense] = []
            for group in fetchedGroups {
                let groupExpenses = try await expenseService.fetchExpenses(forGroup: group.id)
                all.append(contentsOf: groupExpenses)
            }
            
            allExpenses = all
            
            // Compute metrics for current filters
            recomputeForCurrentFilters()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Recomputes metrics for filteredExpenses
    func recomputeForCurrentFilters() {
        guard let userId = authService.currentUserId else { return }
        computeMetrics(for: filteredExpenses, currentUserId: userId)
    }
    
    /// Computes totals for summary + category breakdown
    func computeMetrics(for expenses: [Expense], currentUserId: String) {
        var total = 0.0
        var owe = 0.0
        var owed = 0.0
        var cats: [String: Double] = [:]
        
        for e in expenses {
            total += e.amount
            
            let cat = e.category ?? "Uncategorized"
            cats[cat, default: 0] += e.amount
            
            let pct = e.split[currentUserId] ?? 0
            let share = e.amount * Double(pct) / 100
            
            if e.paidBy == currentUserId {
                let others = e.amount - share
                if others > 0 { owed += others }
            } else {
                if share > 0 { owe += share }
            }
        }
        
        totalSpent = total
        youOwe = owe
        owedToYou = owed
        categoryTotals = cats
    }
    
    func sortedCategoryTotals() -> [(String, Double)] {
        categoryTotals.sorted { $0.value > $1.value }
    }
    
    func formatCurrency(_ value: Double) -> String {
        String(format: "$%.0f", value)
    }
}
