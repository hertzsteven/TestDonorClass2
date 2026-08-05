//
//  NCOAImportSummary.swift
//  TestDonorClass2
//

import Foundation

/// How many rows fell into each outcome, for the counts shown above the preview.
struct NCOAImportSummary: Sendable, Equatable {
    private let counts: [NCOAImportOutcome: Int]

    /// Rows the file contained but that could not be parsed at all.
    let unreadableRowCount: Int

    init(items: [NCOAImportItem], unreadableRowCount: Int = 0) {
        self.counts = Dictionary(grouping: items, by: \.outcome).mapValues(\.count)
        self.unreadableRowCount = unreadableRowCount
    }

    func count(of outcome: NCOAImportOutcome) -> Int {
        counts[outcome] ?? 0
    }

    var applyableCount: Int {
        count(of: .willUpdate)
    }

    var totalCount: Int {
        counts.values.reduce(0, +)
    }
}
