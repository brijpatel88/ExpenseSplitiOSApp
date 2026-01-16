//
//  FirebaseManager.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-18.
//


import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase

final class FirebaseManager {

    // MARK: - Singleton Instance
    static let shared = FirebaseManager()

    // MARK: - Public Firebase References
    let auth: Auth
    let database: DatabaseReference

    // MARK: - Init (Private)
    private init() {
        // Ensure Firebase is initialized
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        self.auth = Auth.auth()
        self.database = Database.database().reference()
    }
}
