//
//  DonorMatchServiceTests.swift
//  TestDonorClass2Tests
//

import Foundation
import Testing
@testable import TestDonorClass2

struct DonorMatchServiceTests {

    private let matcher = DonorMatchService()

    private func donor(
        id: Int,
        first: String? = nil,
        last: String? = nil,
        company: String? = nil,
        street: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zip: String? = nil
    ) -> Donor {
        var donor = Donor(
            company: company,
            firstName: first,
            lastName: last,
            address: street,
            city: city,
            state: state,
            zip: zip
        )
        donor.id = id
        return donor
    }

    private func record(
        first: String? = nil,
        last: String? = nil,
        org: String? = nil,
        street: String? = nil,
        city: String? = nil,
        zip: String? = nil
    ) -> ExternalDonationRecord {
        ExternalDonationRecord(
            rowNumber: 2,
            referenceNumber: "R1",
            source: .zelle,
            date: Date(),
            amount: 18,
            firstName: first,
            lastName: last,
            organizationName: org,
            address: DonorAddress(street: street, city: city, state: "NY", zip: zip),
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
    }

    @Test func exactNameRanksAboveLastNameOnly() {
        let donors = [
            donor(id: 1, first: "Other", last: "Steinmetz"),
            donor(id: 2, first: "Malka", last: "Steinmetz")
        ]

        let candidates = matcher.candidates(
            for: record(first: "malka", last: "steinmetz"),
            among: donors
        )

        #expect(candidates.first?.donor.id == 2)
        #expect(candidates.first?.reason == .exactName)
        #expect(candidates.contains(where: { $0.donor.id == 1 && $0.reason == .lastNameOnly }))
    }

    @Test func organizationNameMatchesCompany() {
        let donors = [donor(id: 9, company: "The Donors Fund")]
        let candidates = matcher.candidates(
            for: record(org: "the donors fund"),
            among: donors
        )
        #expect(candidates.count == 1)
        #expect(candidates[0].reason == .organizationName)
    }

    @Test func addressTieBreakImprovesLastNameMatch() {
        let donors = [
            donor(id: 1, first: "A", last: "Cohen", street: "1 Other St", city: "Brooklyn", state: "NY", zip: "11230"),
            donor(id: 2, first: "B", last: "Cohen", street: "10 Main St", city: "Brooklyn", state: "NY", zip: "11230")
        ]

        let candidates = matcher.candidates(
            for: record(first: "C", last: "Cohen", street: "10 Main Street", city: "Brooklyn", zip: "11230"),
            among: donors
        )

        #expect(candidates.first?.donor.id == 2)
        #expect(candidates.first?.reason == .addressTieBreak)
        #expect(candidates.first!.rank < (candidates.first(where: { $0.donor.id == 1 })?.rank ?? 999))
    }

    @Test func noMatchReturnsEmpty() {
        let candidates = matcher.candidates(
            for: record(first: "Nobody", last: "Here"),
            among: [donor(id: 1, first: "Someone", last: "Else")]
        )
        #expect(candidates.isEmpty)
    }
}
