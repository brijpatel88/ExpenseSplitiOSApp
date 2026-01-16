//
//  GroupService.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-17.
//

import Foundation
import FirebaseDatabase

final class GroupService {
    
    private let db = FirebaseManager.shared.database
    
    // MARK: - Create Group
    func createGroup(
        name: String,
        createdBy: String,
        members: [String],
        description: String? = nil,
        imageUrl: String? = nil
    ) async throws -> ExpenseGroup {
        
        let groupId = UUID().uuidString
        let createdAt = Date()
        
        let group = ExpenseGroup(
            id: groupId,
            name: name,
            createdBy: createdBy,
            createdAt: createdAt,
            members: members,
            description: description,
            imageUrl: imageUrl
        )
        
        // Save main info
        try await db
            .child("groups")
            .child(groupId)
            .setValueAsync(group.asDict)
        
        // Save membership:  { "userId": true }
        try await db
            .child("group_members")
            .child(groupId)
            .setValueAsync(group.membersDict)
        
        return group
    }
    
    // MARK: - Fetch Groups For User
    func fetchGroupsForUser(userId: String) async throws -> [ExpenseGroup] {
        
        // ❗ Use getValueAsync() instead of invalid getData()
        let membersSnapshot = try await db
            .child("group_members")
            .getValueAsync()
        
        var userGroupIds: [String] = []
        
        for groupSnapshot in membersSnapshot.children.allObjects as? [DataSnapshot] ?? [] {
            let groupId = groupSnapshot.key
            if let membersDict = groupSnapshot.value as? [String: Bool],
               membersDict[userId] == true {
                userGroupIds.append(groupId)
            }
        }
        
        if userGroupIds.isEmpty { return [] }
        
        // ❗ Use getValueAsync() here too
        let groupsSnapshot = try await db
            .child("groups")
            .getValueAsync()
        
        var result: [ExpenseGroup] = []
        
        for groupSnapshot in groupsSnapshot.children.allObjects as? [DataSnapshot] ?? [] {
            let groupId = groupSnapshot.key
            
            guard userGroupIds.contains(groupId),
                  let data = groupSnapshot.value as? [String: Any]
            else { continue }
            
            // Pull members safely
            let membersDict = membersSnapshot
                .childSnapshot(forPath: groupId)
                .value as? [String: Bool] ?? [:]
            
            if let group = ExpenseGroup(
                id: groupId,
                data: data,
                membersDict: membersDict
            ) {
                result.append(group)
            }
        }
        
        result.sort { $0.createdAt > $1.createdAt }
        return result
    }
}
