//
//  NCOAImportItem.swift
//  TestDonorClass2
//
//  One NCOA row paired with the decision made about it and the donor details
//  needed to show that decision on screen.
//

import Foundation

struct NCOAImportItem: Identifiable, Sendable {
    let record: NCOARecord
    let outcome: NCOAImportOutcome

    /// The address on file when the preview was built, or nil when no donor row
    /// carried this id.
    let currentAddress: DonorAddress?

    /// The name on file, shown so a mismatched row can be recognized.
    let storedDonorName: String?

    var id: Int { record.donorId }
}
