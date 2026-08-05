//
//  ExternalDonationOutcomeSectionView.swift
//  TestDonorClass2
//

import SwiftUI

struct ExternalDonationOutcomeSectionView: View {
    let outcome: ExternalDonationOutcome
    let items: [ExternalDonationItem]
    let onSelect: (ExternalDonationItem) -> Void

    var body: some View {
        if !items.isEmpty {
            Section {
                ForEach(items) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        ExternalDonationRowView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("\(outcome.title) (\(items.count))")
            } footer: {
                Text(outcome.explanation)
            }
        }
    }
}
