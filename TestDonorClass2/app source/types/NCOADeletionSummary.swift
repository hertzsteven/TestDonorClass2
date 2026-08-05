//
//  NCOADeletionSummary.swift
//  TestDonorClass2
//

import Foundation

/// How many rows fell into each outcome, for the counts shown above the preview.
struct NCOADeletionSummary: Sendable, Equatable {
    private let counts: [NCOADeletionOutcome: Int]

    /// Rows the file contained but that could not be parsed at all.
    let unreadableRowCount: Int

    init(items: [NCOADeletionItem], unreadableRowCount: Int = 0) {
        self.counts = Dictionary(grouping: items, by: \.outcome).mapValues(\.count)
        self.unreadableRowCount = unreadableRowCount
    }

    func count(of outcome: NCOADeletionOutcome) -> Int {
        counts[outcome] ?? 0
    }

    var applyableCount: Int {
        count(of: .willFlag)
    }

    var totalCount: Int {
        counts.values.reduce(0, +)
    }
}
