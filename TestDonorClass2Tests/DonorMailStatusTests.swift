//
//  DonorMailStatusTests.swift
//  TestDonorClass2Tests
//

import Testing
@testable import TestDonorClass2

struct DonorMailStatusTests {

    @Test func onlyActiveAllowsPostalMail() {
        #expect(DonorMailStatus.active.allowsPostalMail)
        #expect(!DonorMailStatus.badAddress.allowsPostalMail)
        #expect(!DonorMailStatus.doNotMail.allowsPostalMail)
        #expect(!DonorMailStatus.deceased.allowsPostalMail)
    }

    @Test func resolveDefaultsNilAndUnknownToActive() {
        #expect(DonorMailStatus.resolve(nil) == .active)
        #expect(DonorMailStatus.resolve("UNKNOWN") == .active)
        #expect(DonorMailStatus.resolve("DO_NOT_MAIL") == .doNotMail)
    }

    @Test func donorAllowsPostalMailUsesResolvedStatus() {
        var donor = Donor(firstName: "Ada", lastName: "Lovelace")
        #expect(donor.allowsPostalMail)

        donor.mailStatus = DonorMailStatus.badAddress.rawValue
        #expect(!donor.allowsPostalMail)

        donor.mailStatus = nil
        #expect(donor.allowsPostalMail)
    }

    @Test func receiptItemFiltersNonMailableFromPrintableSet() {
        let active = ReceiptItem(
            donationId: 1,
            donorName: "Active Donor",
            amount: 50,
            date: .now,
            campaignName: nil,
            status: .requested,
            donorMailStatus: .active
        )
        let blocked = ReceiptItem(
            donationId: 2,
            donorName: "Blocked Donor",
            amount: 75,
            date: .now,
            campaignName: nil,
            status: .requested,
            donorMailStatus: .doNotMail
        )

        let printable = [active, blocked].filter(\.allowsPostalMail)
        #expect(printable.map(\.donationId) == [1])
    }
}
