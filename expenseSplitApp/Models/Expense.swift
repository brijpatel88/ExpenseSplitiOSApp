//
//  Expense.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-07.
//

import Foundation

struct Expense: Identifiable, Codable, Equatable {
    var id: String
    var groupId: String
    var title: String
    var amount: Double
    var paidBy: String
    var date: Date
    
    // Optional: category/subcategory, note, place, currency
    var category: String?
    var subcategory: String?
    var place: String?
    var note: String?
    var currency: String?
    
    // User split mapping: ["userId": percentage]
    var split: [String: Int]
    
    // MARK: - 1️⃣ Full initializer (used when creating new expense)
    init(
        id: String,
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
    ) {
        self.id = id
        self.groupId = groupId
        self.title = title
        self.amount = amount
        self.paidBy = paidBy
        self.date = date
        self.category = category
        self.subcategory = subcategory
        self.place = place
        self.note = note
        self.currency = currency
        self.split = split
    }
    
    // MARK: - 2️⃣ Firebase constructor (used when reading from database)
    init?(id: String, data: [String: Any], split: [String: Int]) {
        guard
            let groupId = data["groupId"] as? String,
            let title = data["title"] as? String,
            let amount = data["amount"] as? Double,
            let paidBy = data["paidBy"] as? String,
            let dateInt = data["date"] as? Int
        else { return nil }
        
        self.id = id
        self.groupId = groupId
        self.title = title
        self.amount = amount
        self.paidBy = paidBy
        self.date = Date(timeIntervalSince1970: TimeInterval(dateInt))
        
        // Optional fields
        self.category = data["category"] as? String
        self.subcategory = data["subcategory"] as? String
        self.place = data["place"] as? String
        self.note = data["note"] as? String
        self.currency = data["currency"] as? String
        
        self.split = split
    }
    
    // MARK: - 3️⃣ Firebase dictionary for saving
    var asDict: [String: Any] {
        [
            "groupId": groupId,
            "title": title,
            "amount": amount,
            "paidBy": paidBy,
            "date": Int(date.timeIntervalSince1970),
            "category": category ?? NSNull(),
            "subcategory": subcategory ?? NSNull(),
            "place": place ?? NSNull(),
            "note": note ?? NSNull(),
            "currency": currency ?? NSNull()
        ]
    }
}
