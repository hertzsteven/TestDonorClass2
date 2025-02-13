//
//  InfoBannerView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/12/25.
//

import SwiftUI

    struct InfoBannerView: View {
        let title: String
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                Text("• Tap + to add a new incentive")
                Text("• Tap any incentive to view or edit details")
                Text("• Swipe left on an incentive to delete")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
