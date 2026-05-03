//
//  DonorAddressFormatterTests.swift
//  TestDonorClass2Tests
//

import Testing
@testable import TestDonorClass2

struct DonorAddressFormatterTests {

    @Test func formatsAllThreePiecesWithCommas() {
        let result = DonorAddressFormatter.formatStreetLine(
            address: "1442 45th St",
            suite: "4B",
            additionalLine: "c/o Office"
        )
        #expect(result == "1442 45th St, Apt/Ste 4B, c/o Office")
    }

    @Test func addressOnly() {
        let result = DonorAddressFormatter.formatStreetLine(
            address: "1442 45th St",
            suite: nil,
            additionalLine: nil
        )
        #expect(result == "1442 45th St")
    }

    @Test func doesNotDoublePrefixWhenSuiteAlreadyLabeled() {
        let result = DonorAddressFormatter.formatStreetLine(
            address: "78 Ocean Parkway",
            suite: "Apt 4B",
            additionalLine: "c/o Building Manager"
        )
        #expect(result == "78 Ocean Parkway, Apt 4B, c/o Building Manager")
    }

    @Test func nilWhenAllEmpty() {
        #expect(DonorAddressFormatter.formatStreetLine(address: nil, suite: nil, additionalLine: nil) == nil)
        #expect(DonorAddressFormatter.formatStreetLine(address: "  ", suite: "\n", additionalLine: "") == nil)
    }

    @Test func numericSuiteGetsPrefix() {
        let result = DonorAddressFormatter.formatStreetLine(
            address: "1 Main",
            suite: "200",
            additionalLine: nil
        )
        #expect(result == "1 Main, Apt/Ste 200")
    }
}
