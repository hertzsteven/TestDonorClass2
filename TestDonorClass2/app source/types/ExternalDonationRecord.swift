//
//  ExternalDonationRecord.swift
//  TestDonorClass2
//
//  One parsed CSV row. Knows nothing about donors or match decisions.
//

import Foundation

struct ExternalDonationRecord: Sendable, Equatable {
    /// One-based line number in the file (header is line 1).
    let rowNumber: Int
    let referenceNumber: String?
    let source: ExternalDonationSource
    let date: Date
    let amount: Double
    let firstName: String?
    let lastName: String?
    let organizationName: String?
    let address: DonorAddress
    let email: String?
    let phone: String?
    let memo: String?
    let hebrewName: String?
    let mothersHebrewName: String?
    let details: String?
    let product: String?
    let messageID: String?
    let reviewNeeded: String?

    /// Key stored on the donation so re-importing the same row is a no-op.
    var importKey: String {
        ExternalDonationKey.make(
            source: source,
            referenceNumber: referenceNumber,
            rowNumber: rowNumber
        )
    }

    var hasReviewNeeded: Bool {
        guard let reviewNeeded else { return false }
        return !reviewNeeded.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Enough identity to create a named donor (person or organization).
    var hasUsableIdentity: Bool {
        if let organizationName, !organizationName.isEmpty { return true }
        if let lastName, !lastName.isEmpty, !isAnonymousName(lastName) { return true }
        if let firstName, !firstName.isEmpty, !isAnonymousName(firstName) { return true }
        return false
    }

    /// True when the row carries an email and/or a postal street address, so
    /// the gift can be processed in the "reachable" group first.
    var hasReachableContact: Bool {
        if let email, !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        if let street = address.street,
           !street.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        return false
    }

    var displayName: String {
        if let organizationName, !organizationName.isEmpty {
            let person = [firstName, lastName]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            return person.isEmpty ? organizationName : "\(person) (\(organizationName))"
        }

        let person = [firstName, lastName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return person.isEmpty ? "Unidentified" : person
    }

    private func isAnonymousName(_ value: String) -> Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .localizedCaseInsensitiveCompare("Anonymous") == .orderedSame
    }
}
