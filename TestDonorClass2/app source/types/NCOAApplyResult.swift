//
//  NCOAApplyResult.swift
//  TestDonorClass2
//

import Foundation

/// The outcome of writing a verified batch of NCOA updates.
struct NCOAApplyResult: Sendable, Equatable {
    let updatedCount: Int

    /// Rows that verified during the preview but no longer did at write time,
    /// because the donor was edited or removed in between. These are left alone.
    let revalidationFailureCount: Int
}
