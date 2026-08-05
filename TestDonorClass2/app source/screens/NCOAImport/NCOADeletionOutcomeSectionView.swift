//
//  NCOADeletionOutcomeSectionView.swift
//  TestDonorClass2
//

import SwiftUI

/// All rows that shared one outcome, with the reason for that outcome in the
/// section footer.
struct NCOADeletionOutcomeSectionView: View {
    let outcome: NCOADeletionOutcome
    let items: [NCOADeletionItem]

    var body: some View {
        if !items.isEmpty {
            Section {
                ForEach(items) { item in
                    NCOADeletionRowView(item: item)
                }
            } header: {
                Text("\(outcome.title) (\(items.count))")
            } footer: {
                Text(outcome.explanation)
            }
        }
    }
}
