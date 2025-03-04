//
//  InfoBannerView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/12/25.
//

import SwiftUI

extension Character {
    var isVowel: Bool {
        let vowels = "aeiouAEIOU"
        return vowels.contains(self)
    }
}

struct InfoBannerView: View {
    let title: String
    let type: String
    @State private var showDetails = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button(action: { showDetails.toggle() }) {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(.primary)
                }
            }
            if showDetails {
                Text("• Tap + to add a new \(type)")
                Text("• Tap any \(type) to view or edit details")
                Text("• Swipe left on \(type.first?.isVowel ?? false ? "an" : "a") \(type) to delete")
                Text("• Pull down to refreh")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    VStack(spacing: 20) {
        InfoBannerView(title: "Donor List", type: "donor")
        InfoBannerView(title: "Campaign List", type: "campaign")
    }
    .padding()
}
