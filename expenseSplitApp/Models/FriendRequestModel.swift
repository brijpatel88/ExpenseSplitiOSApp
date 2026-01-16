//
//  FriendRequestModel.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-22.
//


import Foundation

/// A single friend request between two users.
/// From the perspective of the *current* user, `id` is the "other" user.
struct FriendRequestModel: Identifiable, Hashable {
    
    /// For convenience in lists:
    /// - For incoming requests: this will be the sender's UID.
    /// - For outgoing requests: this will be the target user's UID.
    let id: String
    
    /// User who initiated / sent the request.
    let fromUserId: String
    
    /// Name of the other person (the one you see in the UI).
    let fromName: String
    
    /// Email of the other person (used for display).
    let email: String
    
    /// Convenience init used by FriendService
    init(id: String, fromUserId: String, name: String, email: String) {
        self.id = id
        self.fromUserId = fromUserId
        self.fromName = name
        self.email = email
    }
}
