//
//  expenseSplitAppApp.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-03.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct expenseSplitAppApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // MARK: - Global Environment Objects
    @StateObject private var profileVM = ProfileViewModel()
    
    // MARK: - Theme state
    @AppStorage("appTheme") private var appTheme: String = "system"
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(AuthService.shared)
                .environmentObject(profileVM)
                .tint(.esPrimary)
                .preferredColorScheme(resolvedColorScheme)
        }
    }
    
    // MARK: - Theme resolver
    private var resolvedColorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil   // system mode
        }
    }
}
