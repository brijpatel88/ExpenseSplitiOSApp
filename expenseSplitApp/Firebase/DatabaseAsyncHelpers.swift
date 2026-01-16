//
//  DatabaseAsyncHelpers.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-18.
//

import Foundation
import FirebaseDatabase

extension DatabaseReference {
    
    /// Async wrapper for setValue()
    func setValueAsync(_ value: Any?) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.setValue(value) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Async wrapper for observeSingleEvent(.value)
    func getValueAsync() async throws -> DataSnapshot {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataSnapshot, Error>) in
            self.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            }
        }
    }
    
    /// Async wrapper for removeValue()
    func removeValueAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.removeValue { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
