//
//  ExternalDonationContactFilter.swift
//  TestDonorClass2
//

import Foundation

/// Splits the import wave so reachable donors can be processed first.
enum ExternalDonationContactFilter: String, CaseIterable, Identifiable, Sendable {
    /// Row has an email and/or a postal street address.
    case withContact

    /// Row has neither email nor a postal street address.
    case withoutContact

    var id: String { rawValue }

    var title: String {
        switch self {
        case .withContact: "Has email or address"
        case .withoutContact: "No email or address"
        }
    }

    func matches(_ record: ExternalDonationRecord) -> Bool {
        switch self {
        case .withContact: record.hasReachableContact
        case .withoutContact: !record.hasReachableContact
        }
    }
}
