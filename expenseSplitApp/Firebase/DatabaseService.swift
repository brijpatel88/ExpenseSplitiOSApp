//
//  DatabaseService.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-18.
//


import Foundation
import FirebaseDatabase
import FirebaseAuth

/// Centralized Realtime Database service
/// Provides CRUD operations for Users, Groups, Expenses
final class DatabaseService {

    // MARK: - Properties
    private let db = FirebaseManager.shared.database

    // MARK: - Create User Profile
    /// Saves a user profile when a new account is created.
    func createUserProfile(userId: String, name: String, email: String) async throws {
        let data: [String: Any] = [
            "name": name,
            "email": email,
            "createdAt": Int(Date().timeIntervalSince1970)
        ]

        try await db
            .child("users")
            .child(userId)
            .setValueAsync(data)
    }

    // MARK: - Create Group
    /// Creates a new group and links it to the creator.
    func createGroup(name: String, createdBy: String) async throws -> String {
        let groupId = UUID().uuidString
        let createdAt = Int(Date().timeIntervalSince1970)

        let groupData: [String: Any] = [
            "name": name,
            "createdBy": createdBy,
            "createdAt": createdAt
        ]

        // Save group data
        try await db
            .child("groups")
            .child(groupId)
            .setValueAsync(groupData)

        // Add creator into group_members/{groupId}
        try await db
            .child("group_members")
            .child(groupId)
            .child(createdBy)
            .setValueAsync(true)

        return groupId
    }

    // MARK: - Fetch Groups for a User
    /// Returns an array of groupIds the user belongs to.
    func getGroupsForUser(userId: String) async throws -> [String] {
        // Read entire group_members tree once.
        let snapshot = try await db
            .child("group_members")
            .getValueAsync()
        
        var results: [String] = []

        for child in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
            let groupId = child.key

            // Expect shape: group_members/{groupId}/{userId} = true
            if let members = child.value as? [String: Any],
               let isMember = members[userId] as? Bool,
               isMember == true {
                results.append(groupId)
            }
        }

        return results
    }

    // MARK: - Create Expense
    func addExpense(
        groupId: String,
        title: String,
        amount: Double,
        paidBy: String,
        date: Date
    ) async throws -> String {

        let expenseId = UUID().uuidString
        let timestamp = Int(date.timeIntervalSince1970)

        let data: [String: Any] = [
            "groupId": groupId,
            "title": title,
            "amount": amount,
            "paidBy": paidBy,
            "date": timestamp
        ]

        try await db
            .child("expenses")
            .child(expenseId)
            .setValueAsync(data)

        return expenseId
    }

    // MARK: - Save Expense Split
    func saveExpenseSplit(expenseId: String, splits: [String: Int]) async throws {
        try await db
            .child("expense_splits")
            .child(expenseId)
            .setValueAsync(splits)
    }

    // MARK: - Fetch Expenses for Group
    func getExpensesForGroup(groupId: String) async throws -> [ExpenseDTO] {
        let snapshot = try await db.child("expenses").getValueAsync()
        var results: [ExpenseDTO] = []

        for child in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
            guard
                let value = child.value as? [String: Any],
                let dbGroupId = value["groupId"] as? String,
                dbGroupId == groupId
            else {
                continue
            }

            let title = value["title"] as? String ?? ""
            let amount = value["amount"] as? Double ?? 0
            let paidBy = value["paidBy"] as? String ?? ""

            let date = Date(
                timeIntervalSince1970: TimeInterval(value["date"] as? Int ?? 0)
            )

            results.append(
                ExpenseDTO(
                    id: child.key,
                    groupId: dbGroupId,
                    title: title,
                    amount: amount,
                    paidBy: paidBy,
                    date: date
                )
            )
        }

        return results
    }
}


// MARK: - Expense Data Transfer Object
struct ExpenseDTO: Identifiable {
    let id: String
    let groupId: String
    let title: String
    let amount: Double
    let paidBy: String
    let date: Date
}
