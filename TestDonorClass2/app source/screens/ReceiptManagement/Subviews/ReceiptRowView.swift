//
//  ReceiptRowView.swift
//  TestDonorClass2
//
//  Single-row presentation for a receipt item.
//

import SwiftUI

struct ReceiptRowView: View {
    let receipt: ReceiptItem
    let isSelected: Bool
    let showCheckbox: Bool
    var showBatchChip: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if showCheckbox {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.blue : Color.gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(receipt.donorName)
                        .font(.headline)
                    Spacer()
                    Text(receipt.amount, format: .currency(code: "USD"))
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }

                HStack {
                    Text(receipt.date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    StatusBadge(status: receipt.status)
                }

                if let campaign = receipt.campaignName, !campaign.isEmpty {
                    Text("Campaign: \(campaign)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if showBatchChip {
                    PrintedBatchChipView(printedAt: receipt.printedAt)
                }

                Text("Donation ID: \(receipt.donationId)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

private struct StatusBadge: View {
    let status: ReceiptStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(.capsule)
    }

    private var color: Color {
        switch status {
        case .notRequested: return .gray
        case .requested: return .orange
        case .queued: return .blue
        case .printed: return .green
        case .failed: return .red
        }
    }
}
