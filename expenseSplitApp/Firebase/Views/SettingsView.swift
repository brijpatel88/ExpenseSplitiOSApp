import SwiftUI
import FirebaseAuth

/// Main Settings screen that includes app preferences, a link to ProfileView, and a bottom sign-out button.
struct SettingsView: View {
    // MARK: - Example state for toggles
    @State private var isDarkMode = false
    @State private var notificationsEnabled = true
    @State private var useFaceID = false
    
    // Sign out navigation and alert
    @State private var navigateToSignIn = false
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    // MARK: - Profile Section
                    Section(header: Text("Account")) {
                        NavigationLink(destination: ProfileView()) {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .foregroundColor(.blue)
                                Text("My Profile")
                            }
                        }
                    }
                    
                    // MARK: - Preferences Section
                    Section(header: Text("Preferences")) {
                        Toggle(isOn: $isDarkMode) {
                            Label("Dark Mode", systemImage: "moon.fill")
                        }
                        
                        Toggle(isOn: $notificationsEnabled) {
                            Label("Enable Notifications", systemImage: "bell.fill")
                        }
                        
                        Toggle(isOn: $useFaceID) {
                            Label("Use Face ID", systemImage: "faceid")
                        }
                    }
                    
                    // MARK: - App Info Section
                    Section(header: Text("App Info")) {
                        HStack {
                            Label("Version", systemImage: "info.circle")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.gray)
                        }
                        
                        NavigationLink(destination: AboutView()) {
                            Label("About Expense Splitter", systemImage: "questionmark.circle")
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())

                Spacer()
                
                // MARK: - Sign Out Button at Bottom
                VStack {
                    Button(action: {
                        showSignOutAlert = true
                    }) {
                        Text("Sign Out")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .alert("Sign Out", isPresented: $showSignOutAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Sign Out", role: .destructive) {
                            signOut()
                        }
                    } message: {
                        Text("Are you sure you want to sign out?")
                    }
                    
                    NavigationLink(destination: SignInView(), isActive: $navigateToSignIn) {
                        EmptyView()
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Settings")
        }
    }
    
    // MARK: - Sign Out Function
    private func signOut() {
        do {
            try Auth.auth().signOut()
            navigateToSignIn = true  // Redirects user to SignInView
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

// MARK: - Placeholder About View (for demonstration)
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("About Expense Splitter")
                    .font(.title2)
                    .bold()
                
                Text("""
                Expense Splitter helps you manage shared expenses easily.
                Track who owes whom, create groups for trips or events,
                and stay on top of your balances.
                """)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding()
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("About")
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}
