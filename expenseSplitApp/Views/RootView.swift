//
//  RootView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-05.
//

import SwiftUI

/// RootView chooses between:
/// - SignInView when logged out
/// - ContentView (tabs) when logged in
struct RootView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationStack {
            if authService.isAuthenticated {
                ContentView()
            } else {
                SignInView()
            }
        }
    }
}
#Preview {
    RootView()
        .environmentObject(AuthService.shared)
}
