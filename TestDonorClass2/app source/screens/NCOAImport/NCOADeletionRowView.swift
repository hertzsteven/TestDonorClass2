//
//  NCOADeletionRowView.swift
//  TestDonorClass2
//

import SwiftUI

/// One row of the delete preview: who it is, the address that could not be
/// delivered to, and where the donor's mail status stands.
struct NCOADeletionRowView: View {
    let item: NCOADeletionItem

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(item.storedDonorName ?? item.record.displayName)
                    .bold()
                Spacer()
                Text("ID \(item.record.donorId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            addresses

            if let currentMailStatus = item.currentMailStatus {
                Text("Mail status on file: \(currentMailStatus.displayName)")
                    .font(.caption)
                    .foregroundStyle(
                        currentMailStatus.allowsPostalMail ? Color.secondary : Color.orange
                    )
            }

            if let reason = item.record.reason {
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var addresses: some View {
        switch item.outcome {
        case .willFlag, .alreadyFlagged, .alreadySuppressed:
            if let currentAddress = item.currentAddress {
                NCOAAddressBlockView(label: "Undeliverable address on file", address: currentAddress)
            }

        case .donorNotFound:
            NCOAAddressBlockView(label: "File reports undeliverable", address: item.record.oldAddress)

        case .needsReview:
            if let currentAddress = item.currentAddress {
                NCOAAddressBlockView(label: "On file now", address: currentAddress)
            }
            NCOAAddressBlockView(label: "File reports undeliverable", address: item.record.oldAddress)
        }
    }
}

#Preview {
    List {
        NCOADeletionRowView(
            item: NCOADeletionItem(
                record: NCOADeletionRecord(
                    donorId: 233,
                    firstName: "Nason Arthur",
                    lastName: "Hurowitz",
                    company: "",
                    reason: "Moved No Forwarding Address",
                    oldAddress: DonorAddress(
                        street: "19 Cardinal Rd",
                        city: "Worcester",
                        state: "MA",
                        zip: "01602-1765"
                    )
                ),
                outcome: .willFlag,
                currentAddress: DonorAddress(
                    street: "19 Cardinal Rd",
                    city: "Worcester",
                    state: "MA",
                    zip: "01602-1765"
                ),
                storedDonorName: "Nason Arthur Hurowitz",
                currentMailStatus: .active
            )
        )
    }
}
