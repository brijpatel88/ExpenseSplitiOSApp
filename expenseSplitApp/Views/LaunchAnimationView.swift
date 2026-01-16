//
//  LaunchAnimationView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-19.
//

import SwiftUI

/// A simple launch animation that:
/// - Slides through 3 colored "pages"
/// - Keeps the app logo & title centered
/// - Notifies parent when animation is finished
struct LaunchAnimationView: View {
    
    /// Called when the animation sequence is done.
    let onFinished: () -> Void
    
    /// Current slide index (0, 1, 2…)
    @State private var currentPage: Int = 0
    
    /// Controls logo fade / scale-in effect.
    @State private var showContent: Bool = false
    
    /// Background slide colors (customize to match your video)
    private let colors: [Color] = [
        .orange,
        .blue,
        .green
    ]
    
    var body: some View {
        ZStack {
            // MARK: - Sliding background (pages)
            TabView(selection: $currentPage) {
                ForEach(colors.indices, id: \.self) { index in
                    colors[index]
                        .ignoresSafeArea()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // MARK: - Centered logo & title
            VStack(spacing: 16) {
                Image(systemName: "creditcard.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                    .scaleEffect(showContent ? 1.0 : 0.6)
                    .opacity(showContent ? 1.0 : 0.0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.7), value: showContent)
                
                Text("Expense Splitter")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 10)
                    .animation(.easeOut(duration: 0.5), value: showContent)
            }
        }
        .onAppear {
            showContent = true
            runAnimationSequence()
        }
    }
    
    /// Drives the slide change + final callback.
    private func runAnimationSequence() {
        Task {
            // Small delay before first movement
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            
            // Go through all pages with animation
            for index in 0..<colors.count {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        currentPage = index
                    }
                }
                try? await Task.sleep(nanoseconds: 700_000_000) // 0.7s per slide
            }
            
            // Small pause on last slide
            try? await Task.sleep(nanoseconds: 600_000_000)
            
            // Tell parent that we're done
            await MainActor.run {
                onFinished()
            }
        }
    }
}

#Preview {
    LaunchAnimationView {
        // Preview callback
        print("Launch finished")
    }
}
