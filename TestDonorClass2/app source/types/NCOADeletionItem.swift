//
//  NCOADeletionItem.swift
//  TestDonorClass2
//
//  One delete-file row paired with the decision made about it and the donor
//  details needed to show that decision on screen.
//

import Foundation

struct NCOADeletionItem: Identifiable, Sendable {
    let record: NCOADeletionRecord
    let outcome: NCOADeletionOutcome

    /// The address on file when the preview was built, or nil when no donor row
    /// carried this id.
    let currentAddress: DonorAddress?

    /// The name on file, shown so a mismatched row can be recognized.
    let storedDonorName: String?

    /// Mail status on file at preview time, so the reason for skipping a
    /// suppressed donor is visible.
    let currentMailStatus: DonorMailStatus?

    var id: Int { record.donorId }
}
