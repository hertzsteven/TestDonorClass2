//
//  ExternalDonationKey.swift
//  TestDonorClass2
//
//  Builds the import key stored in donation.transaction_number so a re-run of
//  the same CSV row is a no-op.
//

import Foundation

enum ExternalDonationKey {

    private static let separator = "#"

    /// Stable key for one CSV row. Blank references fall back to the file line
    /// number so the row is still idempotent within a wave.
    static func make(
        source: ExternalDonationSource,
        referenceNumber: String?,
        rowNumber: Int
    ) -> String {
        let reference: String
        if let referenceNumber,
           !referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            reference = referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            reference = "ROW-\(rowNumber)"
        }
        return "\(source.keyToken)\(separator)\(reference)"
    }
}
