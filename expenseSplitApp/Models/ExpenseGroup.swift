//
//  Group.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-17.
//
import Foundation
import SwiftUI

/// The `Group` model represents a group that the user creates.
/// It conforms to `Identifiable` for use in lists, and `Codable` so it can be saved to UserDefaults.
struct ExpenseGroup: Identifiable, Codable {
    var id = UUID()              // Automatically generate a unique ID for each group
    var name: String             // The group’s name (entered by user)
    var description: String      // Short description of the group
    var currency: String         // Selected currency (USD, CAD, etc.)
    var dateCreated: Date        // Automatically recorded when the group is created
    var imageData: Data?         // Optional image data (stored as Data for persistence)
    var members: [String]        // Array of emails or phone numbers of group members
}
