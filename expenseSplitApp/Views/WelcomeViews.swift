//
//  WelcomeViews.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-03.
//

import SwiftUI

struct WelcomeView: View {
    // MARK: - Callback for when user completes or skips welcome
    // This closure lets the parent (RootView) know the welcome is done
    var onGetStarted: (() -> Void)? = nil
    
    // MARK: - UI State
    @State private var currentPage = 0     // Which color slide is showing
    @State private var navigateToNext = false  // Controls navigation to SignInView
    
    // MARK: - Background colors for slides
    private let colors: [Color] = [.orange, .gray, .green, .red]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background Auto-Sliding Colors
                TabView(selection: $currentPage) {
                    ForEach(0..<colors.count, id: \.self) { index in
                        colors[currentPage]
                            .ignoresSafeArea()
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onAppear {
                    startAutoSlide()
                }
                
                // MARK: - Foreground Content (Logo + Text)
                VStack {
                    Spacer()
                    
                    Image(systemName: "creditcard")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.white)
                    
                    Text("Expense Splitter")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    Text("Powered by YourCompany")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 10)
                }
            }
            // MARK: - Navigation Trigger
            // When navigateToNext becomes true → push to SignInView
            .navigationDestination(isPresented: $navigateToNext) {
                SignInView()
                    .navigationBarBackButtonHidden(true)
            }
        }
        // MARK: - When auto-slide finishes, call onGetStarted
        .onChange(of: navigateToNext) { newValue in
            if newValue {
                onGetStarted?()
            }
        }
    }
    
    // MARK: - Auto Slide + Navigate Logic
    private func startAutoSlide() {
        var slideCount = 0
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.6)) {
                currentPage = (currentPage - 1 + colors.count) % colors.count
            }
            slideCount += 1
            
            // After 4 slides → go to next screen
            if slideCount >= colors.count {
                timer.invalidate() // stop timer
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    navigateToNext = true
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
}
