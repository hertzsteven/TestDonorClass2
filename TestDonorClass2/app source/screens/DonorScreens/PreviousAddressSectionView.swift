//
//  PreviousAddressSectionView.swift
//  TestDonorClass2
//
//  Read-only reference to the address a donor used before their most recent
//  move. Shown collapsed because it is rarely needed.
//

import SwiftUI

struct PreviousAddressSectionView: View {
    let address: DonorAddress

    var body: some View {
        Section {
            DisclosureGroup("Previous Address") {
                Text(address.displayLines.joined(separator: "\n"))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
