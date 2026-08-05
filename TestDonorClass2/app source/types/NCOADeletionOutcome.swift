//
//  NCOADeletionOutcome.swift
//  TestDonorClass2
//

import Foundation

/// What the importer decided to do with one delete-file row. Only `willFlag`
/// results in a write, and no outcome ever removes a donor.
enum NCOADeletionOutcome: String, Sendable, CaseIterable, Identifiable {
    /// The address on file matches the undeliverable address and the donor is
    /// still being mailed, so the flag can be set.
    case willFlag

    /// Already flagged as a bad address. Skipped, which is what makes
    /// re-importing the same file harmless.
    case alreadyFlagged

    /// Already Do Not Mail or Deceased. Those describe the person rather than
    /// the address, so they outrank a bad address and are left alone.
    case alreadySuppressed

    /// No donor carries this id. Skipped and reported.
    case donorNotFound

    /// The address on file is not the address the mailing service found
    /// undeliverable, so this donor may have already moved. Skipped and
    /// reported for manual handling.
    case needsReview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .willFlag: "Will flag as Bad Address"
        case .alreadyFlagged: "Already flagged"
        case .alreadySuppressed: "Already suppressed"
        case .donorNotFound: "Donor not found"
        case .needsReview: "Needs review"
        }
    }

    var explanation: String {
        switch self {
        case .willFlag:
            "The address on file is the one the mailing service could not deliver to. Mail Status becomes Bad Address. The donor, the address and the donation history are all kept."
        case .alreadyFlagged:
            "These donors are already marked Bad Address. Nothing to do."
        case .alreadySuppressed:
            "These donors are already Do Not Mail or Deceased, which outranks a bad address. Left unchanged."
        case .donorNotFound:
            "No donor in the database carries this id. Handle these by hand."
        case .needsReview:
            "The address on file is not the one reported undeliverable, so this donor may have already moved. Nothing will be changed."
        }
    }

    var isApplied: Bool { self == .willFlag }

    /// Order the outcomes appear in the preview.
    static let displayOrder: [NCOADeletionOutcome] = [
        .willFlag, .needsReview, .donorNotFound, .alreadySuppressed, .alreadyFlagged
    ]
}
