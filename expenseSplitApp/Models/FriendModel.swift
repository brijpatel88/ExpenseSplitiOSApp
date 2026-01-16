//
//  FriendModel.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-20.
//


import Foundation

/// A friend in the user’s friend list.
/// Stored in `/friends/{uid}/{friendId}` and fetched alongside `/users/{friendId}`.
struct FriendModel: Identifiable, Hashable {
    
    /// Firebase UID of the friend
    let id: String
    
    /// Display name of the friend (from `users/{id}/fullName`)
    let name: String
    
    /// Friend’s email (from `users/{id}/email`)
    let email: String
    
    /// Automatically computed initials for avatar circle
    var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        
        if parts.isEmpty {
            return String(name.prefix(2)).uppercased()
        }
        
        return parts
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()
    }
}
