//
//  ExternalDonationSource.swift
//  TestDonorClass2
//

import Foundation

/// Where an external donation arrived from. Values match the CSV `Source` column.
enum ExternalDonationSource: String, Sendable, CaseIterable, Identifiable {
    case ojc = "OJC"
    case donorsFund = "The Donors Fund"
    case website = "Website (Sola)"
    case zelle = "Zelle"

    var id: String { rawValue }

    var displayName: String { rawValue }

    /// Token used inside the import key stored on `transaction_number`.
    var keyToken: String {
        switch self {
        case .ojc: "OJC"
        case .donorsFund: "DONORS_FUND"
        case .website: "WEBSITE"
        case .zelle: "ZELLE"
        }
    }

    var donationType: DonationType {
        switch self {
        case .ojc, .donorsFund: .organizationDirect
        case .website: .websiteCreditCard
        case .zelle: .zelle
        }
    }

    var donorSource: DonorSource {
        switch self {
        case .ojc, .donorsFund: .certificateOrganization
        case .website: .website
        case .zelle: .zelle
        }
    }

    /// True when every gift from this source attaches to one shared org donor.
    var usesHoldingOrganizationDonor: Bool {
        self == .donorsFund
    }

    static func parse(_ raw: String?) -> ExternalDonationSource? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return ExternalDonationSource(rawValue: trimmed)
    }
}
