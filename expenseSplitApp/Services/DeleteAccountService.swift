//
//  DeleteAccountService.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-21.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

/// Service responsible for fully deleting the current user's account:
/// - Removes user data from Realtime Database
/// - Optionally removes user-specific helper nodes (like userGroups)
/// - Deletes user from FirebaseAuth
///
/// View (SettingsView) is responsible for calling authService.signOut() after success.
struct DeleteAccountService {
    
    static func deleteCurrentUser(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            let error = NSError(
                domain: "DeleteAccountService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Not logged in."]
            )
            completion(.failure(error))
            return
        }
        
        let uid = user.uid
        let db = FirebaseManager.shared.database
        
        let userRef = db.child("users").child(uid)
        let userGroupsRef = db.child("userGroups").child(uid)  // optional helper node
        
        let dispatchGroup = DispatchGroup()
        var firstError: Error?
        
        // 1) Remove main user profile
        dispatchGroup.enter()
        userRef.removeValue { error, _ in
            if let error = error, firstError == nil {
                firstError = error
            }
            dispatchGroup.leave()
        }
        
        // 2) Remove userGroups or other helper node (if used in your schema)
        dispatchGroup.enter()
        userGroupsRef.removeValue { error, _ in
            if let error = error, firstError == nil {
                firstError = error
            }
            dispatchGroup.leave()
        }
        
        // 3) When DB removals are done, delete Auth user
        dispatchGroup.notify(queue: .main) {
            if let firstError {
                completion(.failure(firstError))
                return
            }
            
            user.delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
}
