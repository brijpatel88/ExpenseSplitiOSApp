//
//  UserService.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-22.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class UserService {
    
    private let db = FirebaseManager.shared.database
    
    // Save user profile to /users/<uid>
    func saveUserProfile(uid: String, fullName: String, email: String) async throws {
        let values: [String: Any] = [
            "fullName": fullName,
            "email": email
        ]
        
        try await db.child("users")
            .child(uid)
            .setValueAsync(values)
    }
    
    // Fetch user profile
    func fetchUser(uid: String) async throws -> UserModel? {
        let snapshot = try await db
            .child("users")
            .child(uid)
            .getValueAsync()
        
        if let data = snapshot.value as? [String: Any] {
            return UserModel(id: uid, data: data)
        }
        return nil
    }
}
