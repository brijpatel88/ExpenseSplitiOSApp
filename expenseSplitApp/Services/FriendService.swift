//
//  FriendService.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-22.
//


import Foundation
import FirebaseDatabase
import FirebaseAuth

/// Handles:
///  - sending friend request
///  - accepting friend request
///  - rejecting request
///  - fetching pending requests
///  - fetching friend list
///
/// Database structure used:
///
///  /users/{uid}
///     fullName: ""
///     email: ""
///
///  /friend_requests/{targetUserId}/{fromUserId} = true
///
///  /friends/{uid}/{friendId} = true
///
final class FriendService {
    
    private let db = FirebaseManager.shared.database
    
    // MARK: - Send Friend Request
    func sendFriendRequest(toEmail email: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "FriendService", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Not signed in"
            ])
        }
        
        let myUid = currentUser.uid
        
        // 1. Clean email
        let cleanEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        guard !cleanEmail.isEmpty else {
            throw NSError(domain: "FriendService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid email"
            ])
        }
        
        // 2. Find user with that email
        let allUsersSnap = try await db.child("users").getValueAsync()
        
        var targetUid: String?
        
        for child in allUsersSnap.children.allObjects as? [DataSnapshot] ?? [] {
            guard let data = child.value as? [String: Any] else { continue }
            let userEmail = (data["email"] as? String ?? "").lowercased()
            if userEmail == cleanEmail {
                targetUid = child.key
                break
            }
        }
        
        guard let targetUid else {
            throw NSError(domain: "FriendService", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "No user found with that email"
            ])
        }
        
        if targetUid == myUid {
            throw NSError(domain: "FriendService", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "You cannot add yourself"
            ])
        }
        
        // 3. Check if already friends
        let friendSnap = try await db
            .child("friends")
            .child(myUid)
            .child(targetUid)
            .getValueAsync()
        
        if friendSnap.exists() {
            throw NSError(domain: "FriendService", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "Already friends"
            ])
        }
        
        // 4. Check if already sent a request
        let reqSnap = try await db
            .child("friend_requests")
            .child(targetUid)
            .child(myUid)
            .getValueAsync()
        
        if reqSnap.exists() {
            throw NSError(domain: "FriendService", code: 5, userInfo: [
                NSLocalizedDescriptionKey: "Request already sent"
            ])
        }
        
        // 5. Write request
        try await db
            .child("friend_requests")
            .child(targetUid)
            .child(myUid)
            .setValueAsync(true)
    }
    
    
    // MARK: - Fetch Incoming Requests (requests others sent TO me)
    func fetchIncomingRequests(for uid: String) async throws -> [FriendRequestModel] {
        let snap = try await db
            .child("friend_requests")
            .child(uid)
            .getValueAsync()
        
        guard let dict = snap.value as? [String: Bool] else { return [] }
        
        var results: [FriendRequestModel] = []
        
        for (fromId, _) in dict {
            // Fetch sender user info
            let uSnap = try await db.child("users").child(fromId).getValueAsync()
            guard let data = uSnap.value as? [String: Any] else { continue }
            
            let name = data["fullName"] as? String ?? "Unknown"
            let email = data["email"] as? String ?? ""
            
            let request = FriendRequestModel(
                id: fromId,
                fromUserId: fromId,
                name: name,
                email: email
            )
            results.append(request)
        }
        
        return results
    }
    
    
    // MARK: - Fetch Outgoing Requests (requests I have sent TO others)
    func fetchOutgoingRequests(for uid: String) async throws -> [FriendRequestModel] {
        // We must scan friend_requests to find entries where {targetUid}/{uid} = true
        let rootSnap = try await db
            .child("friend_requests")
            .getValueAsync()
        
        var results: [FriendRequestModel] = []
        
        for targetChild in rootSnap.children.allObjects as? [DataSnapshot] ?? [] {
            let targetUid = targetChild.key
            guard let map = targetChild.value as? [String: Bool] else { continue }
            
            // If current user is listed as sender under this target
            if map.keys.contains(uid) {
                // Get the target user's info
                let uSnap = try await db.child("users").child(targetUid).getValueAsync()
                let data = uSnap.value as? [String: Any] ?? [:]
                
                let name = data["fullName"] as? String ?? "Unknown"
                let email = data["email"] as? String ?? ""
                
                // For outgoing requests, we still use:
                // id = targetUid (the other person)
                // fromUserId = uid (me, the sender)
                let request = FriendRequestModel(
                    id: targetUid,
                    fromUserId: uid,
                    name: name,
                    email: email
                )
                
                results.append(request)
            }
        }
        
        return results
    }
    
    
    // MARK: - Accept Friend Request (makes friendship mutual)
    func acceptRequest(from fromId: String, for myUid: String) async throws {
        
        // 1. Add each other as friends
        try await db
            .child("friends")
            .child(myUid)
            .child(fromId)
            .setValueAsync(true)
        
        try await db
            .child("friends")
            .child(fromId)
            .child(myUid)
            .setValueAsync(true)
        
        // 2. Remove the request
        try await db
            .child("friend_requests")
            .child(myUid)
            .child(fromId)
            .removeValueAsync()
    }
    
    
    // MARK: - Reject Request
    func rejectRequest(from fromId: String, for myUid: String) async throws {
        try await db
            .child("friend_requests")
            .child(myUid)
            .child(fromId)
            .removeValueAsync()
    }
    
    
    // MARK: - Fetch Friend List
    func fetchFriends(for uid: String) async throws -> [FriendModel] {
        let snap = try await db
            .child("friends")
            .child(uid)
            .getValueAsync()
        
        guard let map = snap.value as? [String: Bool] else { return [] }
        
        var results: [FriendModel] = []
        
        for (friendId, _) in map {
            let uSnap = try await db.child("users").child(friendId).getValueAsync()
            guard let data = uSnap.value as? [String: Any] else { continue }
            
            let name = data["fullName"] as? String ?? "Unknown"
            let email = data["email"] as? String ?? ""
            
            results.append(
                FriendModel(id: friendId, name: name, email: email)
            )
        }
        
        return results
    }
}
