//
//  NCOAImportOutcome.swift
//  TestDonorClass2
//

import Foundation

/// What the importer decided to do with one NCOA row. Only `willUpdate` results
/// in a write.
enum NCOAImportOutcome: String, Sendable, CaseIterable, Identifiable {
    /// The address on file matches the old address in the file, so the move is
    /// verified and safe to apply.
    case willUpdate

    /// The donor already sits at the new address. Skipped, which is what makes
    /// re-importing the same file harmless.
    case alreadyCurrent

    /// No donor carries this id. Skipped and reported.
    case donorNotFound

    /// The address on file matches neither the old nor the new address, so the
    /// move cannot be verified. Skipped and reported for manual handling.
    case needsReview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .willUpdate: "Will update"
        case .alreadyCurrent: "Already current"
        case .donorNotFound: "Donor not found"
        case .needsReview: "Needs review"
        }
    }

    var explanation: String {
        switch self {
        case .willUpdate:
            "The address on file matches the old address in the file, so these moves are verified."
        case .alreadyCurrent:
            "These donors already have the new address. Nothing to do."
        case .donorNotFound:
            "No donor in the database carries this id. Handle these by hand."
        case .needsReview:
            "The address on file matches neither the old nor the new address, so the move cannot be verified. Nothing will be changed."
        }
    }

    var isApplied: Bool { self == .willUpdate }

    /// Order the outcomes appear in the preview.
    static let displayOrder: [NCOAImportOutcome] = [
        .willUpdate, .needsReview, .donorNotFound, .alreadyCurrent
    ]
}
