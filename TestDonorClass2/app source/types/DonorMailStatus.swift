//
//  DonorMailStatus.swift
//  TestDonorClass2
//

import Foundation

/// Whether a donor should receive postal mailings.
/// Stored in `donor.mail_status` TEXT via its raw value.
enum DonorMailStatus: String, Codable, CaseIterable, Sendable {
    case active = "ACTIVE"
    case badAddress = "BAD_ADDRESS"
    case doNotMail = "DO_NOT_MAIL"
    case deceased = "DECEASED"

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .badAddress: return "Bad Address"
        case .doNotMail: return "Do Not Mail"
        case .deceased: return "Deceased"
        }
    }

    /// Only active addresses are eligible for postal receipt printing.
    var allowsPostalMail: Bool {
        self == .active
    }

    /// Resolves a stored raw value, defaulting to `.active` for nil/unknown legacy rows.
    static func resolve(_ storedValue: String?) -> DonorMailStatus {
        guard let storedValue, let status = DonorMailStatus(rawValue: storedValue) else {
            return .active
        }
        return status
    }

    static func displayName(forStoredValue storedValue: String?) -> String {
        resolve(storedValue).displayName
    }
}
