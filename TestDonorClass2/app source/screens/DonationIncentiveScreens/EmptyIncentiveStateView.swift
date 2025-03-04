//
//  EmptyIncentiveStateView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 3/4/25.
//


import SwiftUI

struct EmptyIncentiveStateView: View {
    // We're accepting a callback that will be executed when the button is tapped
    let onAddNew: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Visually appealing illustration
            Image(systemName: "gift.circle")
                .font(.system(size: 70))
                .foregroundColor(.blue.opacity(0.7))
                .padding()
            
            Text("No Donation Incentives Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Donation incentives help encourage donors to contribute specific amounts.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .frame(maxWidth: 300)
            
            Button(action: onAddNew) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First Incentive")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }
}

// MARK: - Preview
struct EmptyIncentiveStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode preview
            EmptyIncentiveStateView(onAddNew: {
                print("Add button tapped")
            })
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("Light Mode")
            
            // Dark mode preview
            EmptyIncentiveStateView(onAddNew: {
                print("Add button tapped")
            })
            .previewLayout(.sizeThatFits)
            .padding()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
            
            // Full screen preview
            NavigationView {
                EmptyIncentiveStateView(onAddNew: {
                    print("Add button tapped")
                })
                .navigationTitle("Donation Incentives")
            }
            .previewDisplayName("Full Screen")
        }
    }
}
