//
//  PrintedBatchSectionHeader.swift
//  TestDonorClass2
//
//  Section header for a print batch on the Printed tab.
//

import SwiftUI

struct PrintedBatchSectionHeader: View {
    let group: PrintBatchGroup
    let onRevertBatch: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(group.sectionTitle)
                    .font(.subheadline)
                    .bold()
                if let batch = group.batch {
                    Text(batch.status == .fullyReverted ? "Reverted" : "Printed together")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if group.batch != nil {
                Button("Revert Batch", systemImage: "arrow.uturn.backward", action: onRevertBatch)
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .tint(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}
