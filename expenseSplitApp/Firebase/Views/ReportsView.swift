//
//  ReportsView.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-05.
//

import SwiftUI

/// Displays reports or expense summaries.
struct ReportsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Reports and Summaries")
                .font(.title2)
                .bold()
            
            Text("You can show balance summaries, total spendings, or statistics here.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationTitle("Reports")
    }
}

#Preview {
    ReportsView()
}
