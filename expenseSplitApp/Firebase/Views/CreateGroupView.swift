//
//  CreateGroupView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-17.
//
import SwiftUI
import PhotosUI // Needed for selecting images from photo library

struct CreateGroupView: View {
    
    // MARK: - State variables to track user input
    @State private var groupName = ""                   // Name input
    @State private var groupDescription = ""            // Description input
    @State private var selectedCurrency = "USD"         // Picker for currency
    @State private var selectedImage: PhotosPickerItem? // Raw picked image
    @State private var groupImage: Image?               // SwiftUI display image
    @State private var imageData: Data?                 // Image data to save
    @State private var members: [String] = []           // Added member list
    @State private var newMember = ""                   // Input for new member
    @State private var savedGroups: [ExpenseGroup] = []        // Locally saved groups
    
    // Instance of our local storage service
    private let groupService = GroupService()
    private let currencies = ["USD", "CAD", "INR", "EUR"]
    
    var body: some View {
        NavigationStack {
            // add here scroll
            Form {
                
                // MARK: - 1️⃣ Group Image Picker Section
                Section(header: Text("Group Image")) {
                    VStack {
                        if let groupImage = groupImage {
                            groupImage
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 150)
                                .overlay(Text("No Image Selected"))
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                        
                        // PhotosPicker allows user to select an image
                        PhotosPicker("Select Group Image", selection: $selectedImage, matching: .images)
                            .onChange(of: selectedImage) { newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        self.imageData = data
                                        self.groupImage = Image(uiImage: uiImage)
                                    }
                                }
                            }
                    }
                }
                
                // MARK: - 2️⃣ Group Details Section
                Section(header: Text("Group Details")) {
                    TextField("Enter Group Name", text: $groupName)
                    TextField("Enter Description", text: $groupDescription)
                    
                    // Picker to select currency
                    Picker("Select Currency", selection: $selectedCurrency) {
                        ForEach(currencies, id: \.self) { currency in
                            Text(currency)
                        }
                    }
                    
                    // Show current date
                    HStack {
                        Text("Date Created")
                        Spacer()
                        Text(Date.now.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.gray)
                    }
                }
                
                // MARK: - 3️⃣ Add Members Section
                Section(header: Text("Add Members (Email or Phone)")) {
                    HStack {
                        TextField("Enter member", text: $newMember)
                        Button("Add") {
                            if !newMember.isEmpty {
                                members.append(newMember)
                                newMember = ""
                            }
                        }
                    }
                    
                    // List of members added
                    ForEach(members, id: \.self) { member in
                        Text(member)
                    }
                    .onDelete { indexSet in
                        members.remove(atOffsets: indexSet)
                    }
                }
                
                // MARK: - 4️⃣ Save Button Section
                Section {
                    Button(action: saveGroup) {
                        Label("Save Group", systemImage: "square.and.arrow.down")
                    }
                    // Disable if name or description empty
                    .disabled(groupName.isEmpty || groupDescription.isEmpty)
                }
            }
            .navigationTitle("Create New Group")
            .onAppear {
                // Load saved groups when screen opens
                savedGroups = groupService.loadGroups()
            }
        }
    }
    
    // MARK: - Function to Save Group
    private func saveGroup() {
        let newGroup = ExpenseGroup(
            name: groupName,
            description: groupDescription,
            currency: selectedCurrency,
            dateCreated: Date(),
            imageData: imageData,
            members: members
        )
        
        // Append new group to saved list and store it
        savedGroups.append(newGroup)
        groupService.saveGroups(savedGroups)
        
        // Reset form after saving
        groupName = ""
        groupDescription = ""
        selectedCurrency = "USD"
        groupImage = nil
        imageData = nil
        members.removeAll()
    }
}

#Preview {
    CreateGroupView()
}
