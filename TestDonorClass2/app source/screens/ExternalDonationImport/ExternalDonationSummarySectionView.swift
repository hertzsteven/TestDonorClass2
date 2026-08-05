//
//  ExternalDonationSummarySectionView.swift
//  TestDonorClass2
//

import SwiftUI

struct ExternalDonationSummarySectionView: View {
    let summary: ExternalDonationSummary
    let fileName: String?
    let groupTitle: String

    var body: some View {
        Section("This group · \(groupTitle)") {
            if let fileName {
                LabeledContent("File", value: fileName)
            }

            LabeledContent("Rows in this group") {
                Text(summary.totalCount, format: .number)
                    .bold()
            }

            ForEach(ExternalDonationOutcome.displayOrder) { outcome in
                let count = summary.count(of: outcome)
                if count > 0 {
                    LabeledContent(outcome.title) {
                        Text(count, format: .number)
                            .bold()
                    }
                }
            }

            LabeledContent("Still need a decision") {
                Text(summary.undecidedCount, format: .number)
                    .bold()
                    .foregroundStyle(summary.undecidedCount > 0 ? Color.orange : Color.primary)
            }

            LabeledContent("Ready to write") {
                Text(summary.writableCount, format: .number)
                    .bold()
            }

            if summary.unreadableRowCount > 0 {
                LabeledContent("Rows that could not be read") {
                    Text(summary.unreadableRowCount, format: .number)
                        .bold()
                        .foregroundStyle(Color.orange)
                }
            }
        }
    }
}
