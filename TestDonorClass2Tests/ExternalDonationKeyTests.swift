//
//  ExternalDonationKeyTests.swift
//  TestDonorClass2Tests
//

import Foundation
import Testing
@testable import TestDonorClass2

struct ExternalDonationKeyTests {

    @Test func buildsSourceAndReference() {
        let key = ExternalDonationKey.make(
            source: .ojc,
            referenceNumber: "Certificate# 16625771",
            rowNumber: 2
        )
        #expect(key == "OJC#Certificate# 16625771")
    }

    @Test func blankReferenceFallsBackToRowNumber() {
        let key = ExternalDonationKey.make(
            source: .zelle,
            referenceNumber: nil,
            rowNumber: 17
        )
        #expect(key == "ZELLE#ROW-17")
    }

    @Test func whitespaceOnlyReferenceFallsBackToRowNumber() {
        let key = ExternalDonationKey.make(
            source: .website,
            referenceNumber: "   ",
            rowNumber: 9
        )
        #expect(key == "WEBSITE#ROW-9")
    }

    @Test func donorsFundUsesStableToken() {
        let key = ExternalDonationKey.make(
            source: .donorsFund,
            referenceNumber: "DF-1",
            rowNumber: 3
        )
        #expect(key == "DONORS_FUND#DF-1")
    }

    @Test func reachableContactRequiresEmailOrStreet() {
        let withEmail = ExternalDonationRecord(
            rowNumber: 2,
            referenceNumber: "R1",
            source: .zelle,
            date: Date(),
            amount: 5,
            firstName: "A",
            lastName: "B",
            organizationName: nil,
            address: DonorAddress(),
            email: "a@b.com",
            phone: nil,
            memo: nil,
            hebrewName: nil,
            mothersHebrewName: nil,
            details: nil,
            product: nil,
            messageID: nil,
            reviewNeeded: nil
        )
        let withStreet = ExternalDonationRecord(
            rowNumber: 3,
            referenceNumber: "R2",
            source: .zelle,
            date: Date(),
            amount: 5,
            firstName: "A",
            lastName: "B",
            organizationName: nil,
            address: DonorAddress(street: "10 Main St"),
            email: nil,
            phone: nil,
            memo: nil,
            hebrewName: nil,
            mothersHebrewName: nil,
            details: nil,
            product: nil,
            messageID: nil,
            reviewNeeded: nil
        )
        let neither = ExternalDonationRecord(
            rowNumber: 4,
            referenceNumber: "R3",
            source: .ojc,
            date: Date(),
            amount: 5,
            firstName: "A",
            lastName: "B",
            organizationName: nil,
            address: DonorAddress(city: "Brooklyn"),
            email: nil,
            phone: "555-1212",
            memo: nil,
            hebrewName: nil,
            mothersHebrewName: nil,
            details: nil,
            product: nil,
            messageID: nil,
            reviewNeeded: nil
        )

        #expect(withEmail.hasReachableContact)
        #expect(withStreet.hasReachableContact)
        #expect(!neither.hasReachableContact)
        #expect(ExternalDonationContactFilter.withContact.matches(withEmail))
        #expect(ExternalDonationContactFilter.withoutContact.matches(neither))
    }
}
