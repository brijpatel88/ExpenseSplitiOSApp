//
//  AppTheme.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-20.
//

import SwiftUI

// MARK: - Brand Colors

extension Color {
    
    /// Primary neon blue (brand color)
    static let esPrimary = Color(red: 37/255, green: 99/255, blue: 235/255)   // #2563EB
    
    /// Secondary mint accent
    static let esMint = Color(red: 45/255, green: 212/255, blue: 191/255)     // #2DD4BF
    
    /// Backgrounds
    static let esBackgroundLight = Color(red: 245/255, green: 247/255, blue: 250/255)
    static let esBackgroundDark = Color(red: 20/255, green: 22/255, blue: 25/255)
    
    /// Cards
    static let esCardLight = Color.white
    static let esCardDark  = Color(red: 32/255, green: 33/255, blue: 36/255)
    
    /// Text
    static let esTextPrimaryLight = Color.black
    static let esTextPrimaryDark  = Color.white
    
    static let esTextSecondaryLight = Color.black.opacity(0.6)
    static let esTextSecondaryDark  = Color.white.opacity(0.6)
}

// MARK: - Gradients

extension LinearGradient {
    
    /// Shared brand gradient
    static var esPrimaryGradient: LinearGradient {
        LinearGradient(
            colors: [.esPrimary, .esMint],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Button Styles

struct ESPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.esPrimary)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .shadow(color: Color.esPrimary.opacity(0.4), radius: 8, y: 4)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct ESSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.15))
            .foregroundColor(Color.esPrimary)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - TextField Style

struct ESInputFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Card Container

struct ESCard<Content: View>: View {
    @Environment(\.colorScheme) var cs
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(18)
            .background(cs == .light ? Color.esCardLight : Color.esCardDark)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(cs == .light ? 0.08 : 0.3), radius: 10, y: 6)
    }
}
