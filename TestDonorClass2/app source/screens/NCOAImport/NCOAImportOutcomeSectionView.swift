//
//  NCOAImportOutcomeSectionView.swift
//  TestDonorClass2
//

import SwiftUI

/// All rows that shared one outcome, with the reason for that outcome in the
/// section footer.
struct NCOAImportOutcomeSectionView: View {
    let outcome: NCOAImportOutcome
    let items: [NCOAImportItem]

    var body: some View {
        if !items.isEmpty {
            Section {
                ForEach(items) { item in
                    NCOAImportRowView(item: item)
                }
            } header: {
                Text("\(outcome.title) (\(items.count))")
            } footer: {
                Text(outcome.explanation)
            }
        }
    }
}
