//
//  EnhancedEmptyStateView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/28/25.
//


import SwiftUI

struct EnhancedEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Custom illustration
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
                    .offset(x: -15, y: 0)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue.opacity(0.6))
                    .offset(x: 15, y: 0)
            }
            
            // Primary message
            Text("Please search for a donor")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Secondary hint
            Text("Use the search bar above to find donors by name, company, or ID")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .frame(maxWidth: 300)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// Use this view in your DonorListView in place of the current empty state
// Replace this:
// Text("Please search for a donor").tint(.gray)
// With this:
// EnhancedEmptyStateView()

// MARK: - Preview
struct EnhancedEmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            EnhancedEmptyStateView()
        }
        .background(Color(.systemGray6))
        .previewLayout(.sizeThatFits)
    }
}