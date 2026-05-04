//
//  ReceiptFieldValuesBuilderTests.swift
//  TestDonorClass2Tests
//

import Testing
@testable import TestDonorClass2

struct ReceiptFieldValuesBuilderTests {

    private let sampleOrg = OrganizationInfo(
        name: "Test Org",
        addressLine1: "1 Main",
        city: "Town",
        state: "ST",
        zip: "12345",
        ein: "12-3456789",
        website: nil,
        email: nil,
        phone: nil
    )

    @Test func mapsDonorReceiptAndDonationStrings() {
        let donation = DonationInfo(
            donorName: "Jane Doe",
            donorTitle: "Ms",
            donationAmount: 250,
            date: "May 3, 2026",
            donorAddress: "9 Oak St, Apt/Ste 2",
            donorCity: "Brooklyn",
            donorState: "NY",
            donorZip: "11218",
            receiptNumber: "A2-999"
        )
        let v = ReceiptFieldValuesBuilder.fieldValues(donation: donation, organization: sampleOrg)
        #expect(v.donorName == "Ms. Jane Doe")
        #expect(v.donorAddressBlock.contains("9 Oak St"))
        #expect(v.donorAddressBlock.contains("Brooklyn"))
        #expect(v.receiptDate == "May 3, 2026")
        #expect(v.receiptNumber == "Receipt #: A2-999")
        #expect(v.donationAmount.contains("250"))
        #expect(v.donationAmount.hasPrefix("Donation:"))
        #expect(v.letterDate == "May 3, 2026")
        #expect(v.letterGreeting == "Dear Jane Doe,")
        #expect(v.letterBody.localizedStandardContains("heartfelt"))
        #expect(v.letterBody.localizedStandardContains("250"))
    }

    @Test func anonymousLetterUsesDearFriend() {
        let donation = DonationInfo(
            donorName: "Anonymous",
            donorTitle: nil,
            donationAmount: 50,
            date: "Jun 1, 2026",
            donorAddress: nil,
            donorCity: nil,
            donorState: nil,
            donorZip: nil,
            receiptNumber: nil
        )
        let v = ReceiptFieldValuesBuilder.fieldValues(donation: donation, organization: sampleOrg)
        #expect(v.letterGreeting == "Dear Friend,")
    }

    @Test func receiptNumberPassthroughWhenAlreadyLabeled() {
        let donation = DonationInfo(
            donorName: "A",
            donorTitle: nil,
            donationAmount: 1,
            date: "Jan 1, 2026",
            donorAddress: nil,
            donorCity: nil,
            donorState: nil,
            donorZip: nil,
            receiptNumber: "Receipt #: X1"
        )
        let v = ReceiptFieldValuesBuilder.fieldValues(donation: donation, organization: sampleOrg)
        #expect(v.receiptNumber == "Receipt #: X1")
    }
}
