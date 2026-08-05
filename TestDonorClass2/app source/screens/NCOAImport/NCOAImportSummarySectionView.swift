//
//  NCOAImportSummarySectionView.swift
//  TestDonorClass2
//

import SwiftUI

/// The counts for each outcome, so the size of the change is visible before the
/// list is read.
struct NCOAImportSummarySectionView: View {
    let summary: NCOAImportSummary
    let fileName: String?

    var body: some View {
        Section("What the file contains") {
            if let fileName {
                LabeledContent("File", value: fileName)
            }

            ForEach(NCOAImportOutcome.displayOrder) { outcome in
                LabeledContent(outcome.title) {
                    Text(summary.count(of: outcome), format: .number)
                        .bold()
                }
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
