//
//  DonorCandidate.swift
//  TestDonorClass2
//

import Foundation

enum DonorMatchReason: String, Sendable, Equatable {
    case exactName
    case lastNameOnly
    case organizationName
    case holdingOrganization
    case addressTieBreak

    var displayName: String {
        switch self {
        case .exactName: "Exact name"
        case .lastNameOnly: "Last name"
        case .organizationName: "Organization"
        case .holdingOrganization: "Holding organization"
        case .addressTieBreak: "Address match"
        }
    }
}

/// One ranked donor that might own an external gift.
struct DonorCandidate: Identifiable, Sendable, Equatable {
    let donor: Donor
    let reason: DonorMatchReason
    /// Lower is better. Exact name ranks above last-name-only, and an address
    /// tie-break improves a last-name match.
    let rank: Int

    var id: Int { donor.id ?? 0 }

    var displayName: String {
        let name = [donor.firstName, donor.lastName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        if let company = donor.company, !company.isEmpty {
            return name.isEmpty ? company : "\(name) (\(company))"
        }
        return name.isEmpty ? "Donor #\(donor.id ?? 0)" : name
    }
}
