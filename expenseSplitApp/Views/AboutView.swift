//
//  AboutView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-20.
//


import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                
                // MARK: - App Icon + Title
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color("AccentBlue"), Color("AccentMint")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)
                            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 8)
                        
                        Image(systemName: "creditcard.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 55, height: 55)
                            .foregroundColor(.white)
                    }
                    
                    Text("Expense Splitter")
                        .font(.title.bold())
                        .foregroundColor(Color("AccentBlue"))
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                
                // MARK: - App description card
                VStack(alignment: .leading, spacing: 16) {
                    Text("What is Expense Splitter?")
                        .font(.headline)
                        .foregroundColor(Color("AccentBlue"))
                    
                    Text("""
Expense Splitter helps you manage shared expenses with friends, family, and groups. Whether you're planning a trip, sharing groceries, or tracking bills — the app keeps everything organized.

You can:
• Create groups  
• Add shared expenses  
• Track who owes whom  
• View reports and summaries  
• Manage your profile  
""")
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                }
                .padding()
                .background(Color("CardBackground"))
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                
                // MARK: - Credits card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Powered By")
                        .font(.headline)
                        .foregroundColor(Color("AccentBlue"))
                    
                    HStack(spacing: 14) {
                        Image(systemName: "bolt.fill")
                            .font(.title)
                            .foregroundColor(Color("AccentMint"))
                        
                        Text("Firebase Authentication & Realtime Database")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color("CardBackground"))
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                
                Spacer(minLength: 30)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color("AppBackground"))
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
