//
//  ExternalDonationOutcome.swift
//  TestDonorClass2
//

import Foundation

/// How one external-donation row was classified before the user decides.
enum ExternalDonationOutcome: String, Sendable, CaseIterable, Identifiable {
    /// This reference is already on a donation. Nothing to do.
    case alreadyImported

    /// Same donor already has a gift on this date for this amount.
    case suspectedDuplicate

    /// The file flagged the row for review, so the user must decide.
    case forcedReview

    /// Two or more plausible donors. User must pick or create new.
    case needsChoice

    /// Exactly one plausible donor. User confirms or creates new.
    case likelyMatch

    /// No match, but enough identity to create a donor.
    case newDonor

    /// No usable name or organization. Goes to the Anonymous holding donor.
    case unidentified

    var id: String { rawValue }

    var title: String {
        switch self {
        case .alreadyImported: "Already imported"
        case .suspectedDuplicate: "Suspected duplicate"
        case .forcedReview: "Forced review"
        case .needsChoice: "Needs choice"
        case .likelyMatch: "Likely match"
        case .newDonor: "New donor"
        case .unidentified: "Anonymous / Unidentified"
        }
    }

    var explanation: String {
        switch self {
        case .alreadyImported:
            "These reference numbers already exist on donations. They will be skipped."
        case .suspectedDuplicate:
            "A matching donor already has a gift on the same date for the same amount. Skipped unless you override."
        case .forcedReview:
            "The file marked these rows for review. Confirm a donor, create new, or skip."
        case .needsChoice:
            "More than one donor could match. Pick one, create a new donor, or skip."
        case .likelyMatch:
            "One donor looks like a match. Confirm, create a new donor instead, or skip."
        case .newDonor:
            "No matching donor was found. A new donor will be created with this gift."
        case .unidentified:
            "No usable name or organization. These attach to the Anonymous / Unidentified donor."
        }
    }

    /// Rows that start without a final decision (or need an explicit confirm).
    var requiresDecision: Bool {
        switch self {
        case .forcedReview, .needsChoice, .likelyMatch:
            true
        case .alreadyImported, .suspectedDuplicate, .newDonor, .unidentified:
            false
        }
    }

    static let displayOrder: [ExternalDonationOutcome] = [
        .forcedReview,
        .needsChoice,
        .likelyMatch,
        .newDonor,
        .unidentified,
        .suspectedDuplicate,
        .alreadyImported
    ]
}
