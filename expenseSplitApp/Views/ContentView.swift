//
//  ContentView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-03.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {

            // MARK: - Home
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            // MARK: - Friends
            NavigationStack {
                FriendsView()
            }
            .tabItem {
                Label("Friends", systemImage: "person.2.fill")
            }
            .tag(1)

            // MARK: - Reports
            NavigationStack {
                ReportsView()
            }
            .tabItem {
                Label("Reports", systemImage: "chart.bar.fill")
            }
            .tag(2)

            // MARK: - Settings
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
        .tint(.blue)   // will connect to AppTheme later
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
        .environmentObject(ProfileViewModel())
}
