//
//  SkipSignInView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-12.
//

import SwiftUI

struct SkipSignInView: View {
    //State variable to trigger navigation
    @State private var navigateToHome = false
    
    var body: some View {
        NavigationStack{
            ZStack {
                Color.blue.ignoresSafeArea()
                VStack(spacing: 30) {
                    Spacer()
                    
                    Text("Welcome to Expense Splitter!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    Text("This is the Skip Sign In page.")
                        .foregroundColor(.white)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    //Mark: -Skip Button
                    Button(action: {
                        navigateToHome = true
                    }) {
                        Text("Skip for now")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                            .shadow(radius: 5)
                    }
                    Spacer()
                }
            }
            //Mark: Navigation to HomeView
            .navigationDestination(isPresented: $navigateToHome){HomeView()
            }
        }
    }
}
#Preview {
    SkipSignInView()
}
