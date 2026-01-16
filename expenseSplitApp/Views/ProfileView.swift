//
//  ProfileView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-05.
//

import SwiftUI

/// A SwiftUI view that displays and edits a user's profile information.
/// The user can enter or change their details and save them locally using UserDefaults.
struct ProfileView: View {
    
    // MARK: - Properties
    
    /// The view model that stores and manages the user’s data.
    /// @StateObject ensures it stays alive for the life of this view and updates automatically when data changes.
    @StateObject private var vm = ProfileViewModel()
    
    /// Controls the display of the success alert after saving.
    @State private var showSavedAlert = false

    
    // MARK: - View Body
    var body: some View {
        // NavigationView allows this screen to have a navigation bar title and appear in a navigation stack.
        NavigationView {
            
            // ScrollView allows the screen to scroll when content is tall (e.g., small devices or long bios).
            ScrollView {
                VStack(spacing: 25) { // VStack arranges elements vertically with spacing between them.
                    
                    // MARK: - Profile Image
                    // Displays a placeholder profile icon (system symbol).
                    // Later, you can replace this with an actual user-uploaded photo.
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()             // Allows resizing of the image
                        .scaledToFit()           // Keeps the aspect ratio correct
                        .frame(width: 100, height: 100) // Sets fixed image size
                        .foregroundColor(.blue)  // Icon color
                        .padding(.top, 20)       // Adds space above the image
                    
                    
                    // MARK: - Editable Form Fields
                    // Contains all text fields for user input
                    VStack(alignment: .leading, spacing: 15) {
                        
                        // MARK: Full Name
                        Group {
                            Text("Full Name") // Label above text field
                                .font(.headline)
                            TextField("Enter your name", text: $vm.user.fullName)
                                .textFieldStyle(RoundedBorderTextFieldStyle()) // Makes text field have rounded border
                        }

                        // MARK: Email
                        Group {
                            Text("Email")
                                .font(.headline)
                            TextField("Enter your email", text: $vm.user.email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)   // Keyboard optimized for emails
                                .autocapitalization(.none)     // Prevents auto-capitalization
                        }

                        // MARK: Phone
                        Group {
                            Text("Phone")
                                .font(.headline)
                            TextField("Enter phone number", text: $vm.user.phone)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)       // Numeric keypad for phones
                        }

                        // MARK: Location
                        Group {
                            Text("Location")
                                .font(.headline)
                            TextField("Enter your city/country", text: $vm.user.location)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // MARK: Bio
                        Group {
                            Text("Bio")
                                .font(.headline)
                            TextEditor(text: $vm.user.bio)   // Multi-line text input for bio
                                .frame(height: 100)
                                .overlay(
                                    // Adds a light border around the text editor
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal) // Adds left/right padding inside the form
                    .font(.body)          // Applies consistent font size
                    
                    
                    // MARK: - Save Button
                    // When pressed, it saves the user data to local storage.
                    Button(action: {
                        vm.saveProfile()        // Calls save function from ViewModel
                        showSavedAlert = true   // Triggers success alert
                    }) {
                        Text("Save Profile")
                            .font(.headline)
                            .foregroundColor(.white)  // Text color
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)   // Button background color
                            .cornerRadius(12)         // Rounded edges
                            .shadow(radius: 3)        // Adds subtle shadow
                    }
                    .padding(.horizontal)            // Adds left/right space around the button
                    .alert(isPresented: $showSavedAlert) {
                        // Alert shown after profile is successfully saved
                        Alert(
                            title: Text("Profile Saved ✅"),
                            message: Text("Your profile details have been saved."),
                            dismissButton: .default(Text("OK"))
                        )
                    }

                    Spacer(minLength: 40) // Adds space at bottom for better scroll feel
                }
            }
            .navigationTitle("Edit Profile") // Title displayed at top of screen
        }
    }
}


/// Preview of ProfileView for Xcode’s preview canvas.
#Preview {
    ProfileView()
}
