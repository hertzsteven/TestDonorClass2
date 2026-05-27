//
//  PrintedBatchChipView.swift
//  TestDonorClass2
//
//  Inline label showing when a receipt was printed as part of a batch.
//

import SwiftUI

struct PrintedBatchChipView: View {
    let printedAt: Date?

    var body: some View {
        if let printedAt {
            Text("Batch · \(printedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
