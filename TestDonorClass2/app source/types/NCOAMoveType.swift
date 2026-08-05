//
//  NCOAMoveType.swift
//  TestDonorClass2
//

import Foundation

/// The NCOALink move type reported for a change of address.
enum NCOAMoveType: String, Sendable, CaseIterable {
    case individual = "I"
    case family = "F"
    case business = "B"

    var displayName: String {
        switch self {
        case .individual: "Individual move"
        case .family: "Family move"
        case .business: "Business move"
        }
    }

    /// Nil for a blank or unrecognized code, which is reported rather than guessed.
    static func resolve(_ rawValue: String?) -> NCOAMoveType? {
        guard let rawValue else { return nil }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return NCOAMoveType(rawValue: trimmed)
    }
}
