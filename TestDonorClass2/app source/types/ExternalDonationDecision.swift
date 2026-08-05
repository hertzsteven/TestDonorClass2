//
//  ExternalDonationDecision.swift
//  TestDonorClass2
//

import Foundation

/// What the user (or a default) chose to do with one external-donation row.
enum ExternalDonationDecision: Sendable, Equatable {
    /// Still waiting on a human choice.
    case pending

    /// Attach the gift to an existing donor.
    case attach(donorId: Int)

    /// Create a new donor from the CSV identity, then attach the gift.
    case createNew

    /// Attach to the shared Anonymous / Unidentified donor.
    case anonymous

    /// Leave this row alone.
    case skip

    var willWrite: Bool {
        switch self {
        case .attach, .createNew, .anonymous: true
        case .pending, .skip: false
        }
    }

    var isReady: Bool {
        self != .pending
    }

    var shortLabel: String {
        switch self {
        case .pending: "Needs decision"
        case .attach(let donorId): "Attach to #\(donorId)"
        case .createNew: "Create new donor"
        case .anonymous: "Anonymous"
        case .skip: "Skip"
        }
    }
}
