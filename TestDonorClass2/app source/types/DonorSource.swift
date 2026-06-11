//
//  DonorSource.swift
//  TestDonorClass2
//

import Foundation

/// Where a donor originally came from (acquisition channel).
/// Stored in the existing `donor.donor_source` TEXT column via its raw value.
enum DonorSource: String, Codable, CaseIterable {
    case zelle = "ZELLE"
    case certificateOrganization = "CERT_ORG"
    case website = "WEBSITE"
    case mailingList = "MAILING_LIST"
    case referral = "REFERRAL"
    case other = "OTHER"

    var displayName: String {
        switch self {
        case .zelle: return "Zelle"
        case .certificateOrganization: return "Certificate Organization"
        case .website: return "Website"
        case .mailingList: return "Mailing List"
        case .referral: return "Personal Referral"
        case .other: return "Other"
        }
    }

    /// Resolves a stored raw value to a display name, falling back to the
    /// raw text for legacy values that predate this enum.
    static func displayName(forStoredValue storedValue: String) -> String {
        DonorSource(rawValue: storedValue)?.displayName ?? storedValue
    }
}
