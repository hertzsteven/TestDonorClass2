//
//  NCOAImportRowView.swift
//  TestDonorClass2
//

import SwiftUI

/// One row of the preview: who it is, what the change would be, and where the
/// addresses came from.
struct NCOAImportRowView: View {
    let item: NCOAImportItem

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

            NCOAMoveDetailView(record: item.record)
        }
    }

    @ViewBuilder
    private var addresses: some View {
        switch item.outcome {
        case .willUpdate:
            if let currentAddress = item.currentAddress {
                NCOAAddressBlockView(label: "On file now", address: currentAddress)
            }
            NCOAAddressBlockView(label: "Changing to", address: item.record.newAddress)

        case .alreadyCurrent:
            if let currentAddress = item.currentAddress {
                NCOAAddressBlockView(label: "On file now", address: currentAddress)
            }

        case .donorNotFound:
            NCOAAddressBlockView(label: "File reports old", address: item.record.oldAddress)
            NCOAAddressBlockView(label: "File reports new", address: item.record.newAddress)

        case .needsReview:
            if let currentAddress = item.currentAddress {
                NCOAAddressBlockView(label: "On file now", address: currentAddress)
            }
            NCOAAddressBlockView(label: "File expected to find", address: item.record.oldAddress)
            NCOAAddressBlockView(label: "File reports new", address: item.record.newAddress)
        }
    }
}

#Preview {
    List {
        NCOAImportRowView(
            item: NCOAImportItem(
                record: NCOARecord(
                    donorId: 2755,
                    firstName: "Yaakov",
                    lastName: "Blau",
                    company: "",
                    newAddress: DonorAddress(
                        street: "1785 E 27th St",
                        city: "Brooklyn",
                        state: "NY",
                        zip: "11229-2510"
                    ),
                    oldAddress: DonorAddress(
                        street: "2277 Homecrest Ave",
                        suite: "6G",
                        city: "Brooklyn",
                        state: "NY",
                        zip: "11229-4121"
                    ),
                    moveType: .family,
                    moveDate: Date()
                ),
                outcome: .willUpdate,
                currentAddress: DonorAddress(
                    street: "2277 HOMECREST AVE",
                    suite: "6G",
                    city: "Brooklyn",
                    state: "NY",
                    zip: "11229-4121"
                ),
                storedDonorName: "Yaakov Blau"
            )
        )
    }
}
