//
//  WelcomeViews.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-03.
//

import SwiftUI

struct WelcomeView: View {
    var onGetStarted: (() -> Void)? = nil
    
    @State private var currentPage = 0
    private let colors: [Color] = [.orange, .blue, .green, .red]
    
    var body: some View {
        ZStack {
            colors[currentPage]
                .ignoresSafeArea()
            
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
                
                Text("Track, split, and settle shared expenses with ease.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                
                Spacer()
                
                Button {
                    onGetStarted?()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(20)
                }
                
                Text("Powered by YourCompany")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 10)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            startAutoSlide()
        }
    }
    
    private func startAutoSlide() {
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.6)) {
                currentPage = (currentPage + 1) % colors.count
            }
        }
    }
}

#Preview {
    WelcomeView()
}
