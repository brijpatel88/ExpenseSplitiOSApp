//
//  DebugConfig.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-28.
//


import Foundation

/// Global debug flags for testing without touching Firebase.
enum DebugConfig {
    /// Enable dummy friends instead of Firebase friends
    static let useDummyFriends = true

    /// How many dummy friends should load?
    static let dummyFriendCount = 6
}
