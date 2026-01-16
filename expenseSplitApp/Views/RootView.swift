//
//  RootView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-05.
//

import SwiftUI
import FirebaseAuth

/// The RootView decides which screen to show based on authentication state.
struct RootView: View {
    // MARK: - State to track authentication status
    @State private var isLoggedIn = Auth.auth().currentUser != nil
    @State private var showWelcome = true  // To show Welcome screen first
    
    var body: some View {
        NavigationStack {
            if showWelcome {
                // First screen: Welcome
                WelcomeView(onGetStarted: {
                    showWelcome = false
                })
            } else {
                if isLoggedIn {
                    // Once logged in → go to Home (ContentView)
                    ContentView()
                        .onAppear {
                            // Keep checking auth changes dynamically
                            Auth.auth().addStateDidChangeListener { _, user in
                                isLoggedIn = (user != nil)
                            }
                        }
                } else {
                    // Not logged in → show SignInView
                    SignInView()
                }
            }
        }
    }
}

#Preview {
    RootView()
}
