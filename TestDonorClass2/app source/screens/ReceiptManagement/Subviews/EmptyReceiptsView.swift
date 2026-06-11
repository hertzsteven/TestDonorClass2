//
//  EmptyReceiptsView.swift
//  TestDonorClass2
//
//  Empty state shown when the filtered list is empty.
//

import SwiftUI

struct EmptyReceiptsView: View {
    let status: ReceiptStatus
    let hasActiveFilter: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "printer.filled.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No receipts found")
                .font(.headline)

            Text(message)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var message: String {
        if hasActiveFilter {
            return "No receipts match your filters"
        }
        return "There are no \(statusPhrase) receipts"
    }

    /// Lowercase phrase that reads naturally after "no … receipts".
    /// Avoids awkward double-negatives like "no not requested receipts".
    private var statusPhrase: String {
        switch status {
        case .notRequested:  return "pending"
        case .digitallySent: return "digitally sent"
        case .requested:     return "requested"
        case .queued:        return "queued"
        case .printed:       return "printed"
        case .failed:        return "failed"
        }
    }
}
