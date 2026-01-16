//
//  AuthService.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-31.
//

import Foundation
import FirebaseAuth
import Combine

/// Global Authentication Service
/// - Handles Firebase Auth
/// - Tracks auth state for the whole app
/// - Provides login, signup, reset, signout
final class AuthService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AuthService()
    private init() {
        setupAuthListener()
    }
    
    // MARK: - Published State (UI reacts automatically)
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    // MARK: - Convenience
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    var currentUserId: String? {
        currentUser?.uid
    }
    
    var firebaseUser: User? {
        currentUser
    }
    
    // MARK: - Auth State Listener
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
            }
        }
    }
    
    // MARK: - SIGN IN (callback style for SignInView)
    func signIn(
        email: String,
        password: String,
        completion: @escaping (Result<User, Error>) -> Void
    ) {
        errorMessage = nil
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                if let user = result?.user {
                    self.currentUser = user
                    completion(.success(user))
                } else {
                    let err = NSError(
                        domain: "AuthError",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown sign-in error."]
                    )
                    self.errorMessage = err.localizedDescription
                    completion(.failure(err))
                }
            }
        }
    }
    
    // MARK: - SIGN UP (async style for CreateAccountView)
    @MainActor
    func signUp(email: String, password: String) async throws -> User {
        errorMessage = nil
        isLoading = true
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = result.user
            self.currentUser = user
            isLoading = false
            return user
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - RESET PASSWORD
    func sendPasswordReset(email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email, completion: completion)
    }
    
    // MARK: - SIGN OUT
    func signOut() {
        errorMessage = nil
        do {
            try Auth.auth().signOut()
            currentUser = nil
        } catch {
            print("Sign out failed: \(error.localizedDescription)")
        }
    }
}
