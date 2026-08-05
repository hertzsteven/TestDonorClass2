//
//  ExternalDonationApplyResultSectionView.swift
//  TestDonorClass2
//

import SwiftUI

struct ExternalDonationApplyResultSectionView: View {
    let result: ExternalDonationApplyResult

    var body: some View {
        Section("Last apply") {
            LabeledContent("Donors created") {
                Text(result.donorsCreated, format: .number)
                    .bold()
            }
            LabeledContent("Donations created") {
                Text(result.donationsCreated, format: .number)
                    .bold()
            }
            LabeledContent("Skipped") {
                Text(result.skippedCount, format: .number)
            }
            if result.revalidationFailureCount > 0 {
                LabeledContent("Could not re-validate") {
                    Text(result.revalidationFailureCount, format: .number)
                        .bold()
                        .foregroundStyle(Color.orange)
                }
            }
        }
    }
}
