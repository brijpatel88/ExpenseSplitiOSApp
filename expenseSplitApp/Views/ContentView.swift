//
//  ContentView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-03.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Body
    var body: some View {
        // A `TabView` provides tab-based navigation at the bottom of the screen.
        TabView {
            
            // MARK: - 1️⃣ Home Screen
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // MARK: - 2️⃣ Create New Group
            CreateGroupView()
                .tabItem {
                    Label("Add Group", systemImage: "plus.circle.fill")
                }
                .tag(1)
            
            // MARK: - 3️⃣ Reports / Summary Screen
            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            // MARK: - 4️⃣ Profile / Settings Screen
            SettingsView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(3)
        }
        // You can customize tab bar appearance if desired
        .tint(.blue) // Changes the selected tab color
        .navigationBarBackButtonHidden(true) // <-- Hide back button if shown in a nav stack
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
