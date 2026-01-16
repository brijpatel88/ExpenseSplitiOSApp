//
//  GroupDetailView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-05.
//
import SwiftUI

/// `GroupDetailView` shows the full details of a selected expense group.
/// It is displayed when a user taps on a group card in the HomeView.
struct GroupDetailView: View {
    // MARK: - Input data
    let group: ExpenseGroup  // The specific group passed from HomeView
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // MARK: - Group Header Image
                if let data = group.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 6)
                        .padding(.horizontal)
                } else {
                    // If no custom image, show a colorful gradient placeholder
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 220)
                        .overlay(
                            Text(group.name.prefix(2).uppercased())
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                        )
                        .padding(.horizontal)
                }
                
                // MARK: - Basic Information Card
                VStack(alignment: .leading, spacing: 10) {
                    Text(group.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(group.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    HStack {
                        Label("\(group.members.count) Members", systemImage: "person.3.fill")
                        Spacer()
                        Label(group.currency, systemImage: "dollarsign.circle.fill")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    HStack {
                        Label("Created", systemImage: "calendar")
                        Spacer()
                        Text(group.dateCreated.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(16)
                .shadow(radius: 4)
                .padding(.horizontal)
                
                // MARK: - Members Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Members")
                        .font(.headline)
                    
                    if group.members.isEmpty {
                        Text("No members added yet.")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(group.members, id: \.self) { member in
                            HStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.8))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(String(member.prefix(1)).uppercased())
                                            .foregroundColor(.white)
                                            .font(.caption)
                                    )
                                Text(member)
                                    .font(.body)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // MARK: - Placeholder for Future: Expenses Section
                VStack(spacing: 8) {
                    Text("Expenses")
                        .font(.headline)
                    Text("No expenses yet. You can add expenses in the future.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    GroupDetailView(group: ExpenseGroup(
        name: "Weekend Trip",
        description: "Expenses for our Niagara Falls weekend getaway.",
        currency: "CAD",
        dateCreated: Date(),
        imageData: nil,
        members: ["Alice", "Bob", "Charlie"]
    ))
}
