//
//  ExternalDonationItem.swift
//  TestDonorClass2
//

import Foundation

/// One CSV row paired with its classification, ranked candidates, and decision.
struct ExternalDonationItem: Identifiable, Sendable, Equatable {
    let record: ExternalDonationRecord
    let outcome: ExternalDonationOutcome
    let candidates: [DonorCandidate]
    var decision: ExternalDonationDecision

    var id: Int { record.rowNumber }

    var selectedDonor: Donor? {
        guard case .attach(let donorId) = decision else {
            return candidates.first?.donor
        }
        return candidates.first(where: { $0.donor.id == donorId })?.donor
            ?? candidates.first?.donor
    }
}
