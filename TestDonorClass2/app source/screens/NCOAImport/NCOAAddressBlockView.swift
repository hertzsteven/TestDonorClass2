//
//  NCOAAddressBlockView.swift
//  TestDonorClass2
//

import SwiftUI

/// One labeled address, used to place the address on file beside the addresses
/// the file reports.
struct NCOAAddressBlockView: View {
    let label: String
    let address: DonorAddress

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            if address.displayLines.isEmpty {
                Text("No address")
                    .font(.callout)
                    .italic()
                    .foregroundStyle(.secondary)
            } else {
                ForEach(address.displayLines, id: \.self) { line in
                    Text(line)
                        .font(.callout)
                }
            }
        }
    }
}

#Preview {
    NCOAAddressBlockView(
        label: "New address",
        address: DonorAddress(
            street: "1785 E 27th St",
            city: "Brooklyn",
            state: "NY",
            zip: "11229-2510"
        )
    )
    .padding()
}
