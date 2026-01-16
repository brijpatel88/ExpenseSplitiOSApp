//
//  ExpenseService.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-07.
//

import Foundation
import FirebaseDatabase

final class ExpenseService {
    
    // Firebase reference
    private let db = FirebaseManager.shared.database
    
    // MARK: - Create Expense
    func createExpense(
        groupId: String,
        title: String,
        amount: Double,
        paidBy: String,
        date: Date,
        category: String? = nil,
        subcategory: String? = nil,
        place: String? = nil,
        note: String? = nil,
        currency: String? = nil,
        split: [String: Int]
    ) async throws -> Expense {
        
        let expenseId = UUID().uuidString
        
        // Create model
        let expense = Expense(
            id: expenseId,
            groupId: groupId,
            title: title,
            amount: amount,
            paidBy: paidBy,
            date: date,
            category: category,
            subcategory: subcategory,
            place: place,
            note: note,
            currency: currency,
            split: split
        )
        
        // Save main data → /expenses/{id}
        try await db
            .child("expenses")
            .child(expenseId)
            .setValueAsync(expense.asDict)
        
        // Save split → /expense_splits/{id}
        try await db
            .child("expense_splits")
            .child(expenseId)
            .setValueAsync(split)
        
        return expense
    }
    
    // MARK: - Fetch Expenses For a Group
    func fetchExpenses(forGroup groupId: String) async throws -> [Expense] {
        
        // 🔁 Use your async helper instead of getData()
        let expensesSnap = try await db
            .child("expenses")
            .getValueAsync()
        
        let splitsSnap = try await db
            .child("expense_splits")
            .getValueAsync()
        
        var list: [Expense] = []
        
        for child in expensesSnap.children.allObjects as? [DataSnapshot] ?? [] {
            let expenseId = child.key
            
            guard let data = child.value as? [String: Any] else { continue }
            
            // Filter by group
            guard let storedGroupId = data["groupId"] as? String,
                  storedGroupId == groupId else { continue }
            
            // Get split
            let splitDict = splitsSnap
                .childSnapshot(forPath: expenseId)
                .value as? [String: Int] ?? [:]
            
            if let exp = Expense(id: expenseId, data: data, split: splitDict) {
                list.append(exp)
            }
        }
        
        return list.sorted { $0.date > $1.date }
    }
    
    // MARK: - Delete Expense
    func deleteExpense(expenseId: String) async throws {
        try await db.child("expenses").child(expenseId).removeValueAsync()
        try await db.child("expense_splits").child(expenseId).removeValueAsync()
    }
}
