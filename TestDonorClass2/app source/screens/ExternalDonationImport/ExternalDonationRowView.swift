//
//  ExternalDonationRowView.swift
//  TestDonorClass2
//

import SwiftUI

struct ExternalDonationRowView: View {
    let item: ExternalDonationItem

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.record.displayName)
                    .bold()
                    .foregroundStyle(Color.primary)
                Spacer()
                Text(
                    item.record.amount,
                    format: .currency(code: "USD").precision(.fractionLength(2))
                )
                .foregroundStyle(Color.primary)
            }

            HStack {
                Text(item.record.source.displayName)
                Text("·")
                Text(item.record.date, format: .dateTime.month(.abbreviated).day().year())
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let reference = item.record.referenceNumber {
                Text(reference)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack {
                if item.record.email != nil {
                    Text("Email")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let street = item.record.address.street, !street.isEmpty {
                    Text("Address")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if !item.record.hasReachableContact {
                    Text("No contact")
                        .font(.caption2)
                        .foregroundStyle(Color.orange)
                }
            }

            HStack {
                Text(item.decision.shortLabel)
                    .font(.caption)
                    .foregroundStyle(item.decision.isReady ? Color.secondary : Color.orange)
                if let top = item.candidates.first {
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(top.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if let review = item.record.reviewNeeded {
                Text(review)
                    .font(.caption2)
                    .foregroundStyle(Color.orange)
            }
        }
        .padding(.vertical, 2)
    }
}
