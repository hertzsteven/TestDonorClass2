//
//  ExternalDonationSummary.swift
//  TestDonorClass2
//

import Foundation

/// Counts for the preview header.
struct ExternalDonationSummary: Sendable, Equatable {
    private let counts: [ExternalDonationOutcome: Int]
    let unreadableRowCount: Int
    let undecidedCount: Int
    let writableCount: Int

    init(items: [ExternalDonationItem], unreadableRowCount: Int = 0) {
        self.counts = Dictionary(grouping: items, by: \.outcome).mapValues(\.count)
        self.unreadableRowCount = unreadableRowCount
        self.undecidedCount = items.filter { !$0.decision.isReady }.count
        self.writableCount = items.filter(\.decision.willWrite).count
    }

    func count(of outcome: ExternalDonationOutcome) -> Int {
        counts[outcome] ?? 0
    }

    var totalCount: Int {
        counts.values.reduce(0, +)
    }

    var applyableCount: Int {
        undecidedCount == 0 ? writableCount : 0
    }
}
