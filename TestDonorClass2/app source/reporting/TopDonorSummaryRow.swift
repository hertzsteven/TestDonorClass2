//
//  TopDonorSummaryRow.swift
//  TestDonorClass2
//

import SwiftUI

/// One expandable row in the Top Donors report — header shows aggregate
/// stats, expanded section shows each individual donation.
struct TopDonorSummaryRow: View {
    let summary: TopDonorSummary
    let rank: Int

    @State private var isExpanded: Bool = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            TopDonorDonationsList(donations: summary.donations)
        } label: {
            TopDonorSummaryHeader(summary: summary, rank: rank)
        }
    }
}

private struct TopDonorSummaryHeader: View {
    let summary: TopDonorSummary
    let rank: Int

    var body: some View {
        HStack(alignment: .top) {
            Text("#\(rank)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .leading)

            VStack(alignment: .leading) {
                Text(summary.donorName)
                    .font(.headline)
                Text(
                    "\(summary.donationCount) donation\(summary.donationCount == 1 ? "" : "s") · avg "
                ) +
                Text(summary.averageAmount, format: .currency(code: "USD"))
                    .font(.caption)
            }
            .accessibilityElement(children: .combine)

            Spacer()

            VStack(alignment: .trailing) {
                Text(summary.totalAmount, format: .currency(code: "USD"))
                    .font(.headline)
                    .foregroundStyle(.green)
                Text("Latest: \(summary.latestDonationDate, format: .dateTime.month().day().year())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct TopDonorDonationsList: View {
    let donations: [TopDonorDonationLine]

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(donations) { line in
                TopDonorDonationLineRow(line: line)
                if line.id != donations.last?.id {
                    Divider()
                }
            }
        }
        .padding(.leading)
    }
}

private struct TopDonorDonationLineRow: View {
    let line: TopDonorDonationLine

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(line.campaignName)
                    .font(.subheadline)
                Text(line.donationDate, format: .dateTime.month().day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(line.amount, format: .currency(code: "USD"))
                .font(.subheadline)
                .foregroundStyle(.green)
        }
        .padding(.vertical, 2)
    }
}
