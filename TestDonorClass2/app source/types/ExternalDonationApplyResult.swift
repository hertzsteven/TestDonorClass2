//
//  ExternalDonationApplyResult.swift
//  TestDonorClass2
//

import Foundation

/// Outcome of writing a decided batch of external donations.
struct ExternalDonationApplyResult: Sendable, Equatable {
    let donorsCreated: Int
    let donationsCreated: Int
    let skippedCount: Int

    /// Rows that were ready at preview time but could no longer be applied
    /// (for example the chosen donor disappeared). Left alone.
    let revalidationFailureCount: Int
}
