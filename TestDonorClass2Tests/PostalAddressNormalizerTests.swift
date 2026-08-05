//
//  PostalAddressNormalizerTests.swift
//  TestDonorClass2Tests
//

import Testing
@testable import TestDonorClass2

struct PostalAddressNormalizerTests {

    // MARK: - Casing, whitespace and punctuation

    @Test func casingIsIgnored() {
        #expect(normalized("10 Roosevelt Ave") == normalized("10 ROOSEVELT AVE"))
    }

    @Test func repeatedAndSurroundingWhitespaceIsIgnored() {
        #expect(normalized("  10   Roosevelt  Ave ") == normalized("10 Roosevelt Ave"))
    }

    @Test func punctuationIsIgnored() {
        #expect(normalized("10 Roosevelt Ave.") == normalized("10 Roosevelt Ave"))
        #expect(normalized("#717") == normalized("717"))
        #expect(normalized("1442 45th St., Apt. 4-B") == normalized("1442 45TH ST APT 4 B"))
    }

    @Test func diacriticsAreFolded() {
        #expect(normalized("Cañon Rd") == normalized("Canon Rd"))
    }

    @Test func nilAndBlankReduceToTheSameEmptyKey() {
        #expect(normalized(nil).isEmpty)
        #expect(normalized("").isEmpty)
        #expect(normalized("   \n ").isEmpty)
    }

    // MARK: - USPS abbreviations

    @Test func writtenOutSuffixesMatchTheirAbbreviations() {
        let pairs = [
            ("Avenue", "Ave"),
            ("Street", "St"),
            ("Road", "Rd"),
            ("Drive", "Dr"),
            ("Boulevard", "Blvd"),
            ("Court", "Ct"),
            ("Lane", "Ln"),
            ("Place", "Pl"),
            ("Terrace", "Ter"),
            ("Parkway", "Pkwy"),
            ("Circle", "Cir"),
            ("Highway", "Hwy"),
            ("Turnpike", "Tpke"),
            ("Square", "Sq")
        ]

        for (spelledOut, abbreviated) in pairs {
            #expect(
                normalized("10 Roosevelt \(spelledOut)") == normalized("10 Roosevelt \(abbreviated)"),
                "\(spelledOut) should match \(abbreviated)"
            )
        }
    }

    @Test func directionalsMatchTheirAbbreviations() {
        #expect(normalized("100 North Main St") == normalized("100 N Main St"))
        #expect(normalized("100 Southwest Blvd") == normalized("100 SW Blvd"))
    }

    @Test func unitDesignatorsMatchTheirAbbreviations() {
        #expect(normalized("Apartment 3") == normalized("Apt 3"))
        #expect(normalized("Suite 200") == normalized("Ste 200"))
        #expect(normalized("Floor 2") == normalized("Fl 2"))
    }

    @Test func unrecognizedWordsPassThroughUnchanged() {
        #expect(normalized("Clinton Path") == "CLINTON PATH")
        #expect(normalized("Homecrest") == "HOMECREST")
    }

    @Test func differentAddressesStillDiffer() {
        #expect(normalized("10 Roosevelt Ave") != normalized("11 Roosevelt Ave"))
        #expect(normalized("2277 Homecrest Ave") != normalized("1785 E 27th St"))
    }

    // MARK: - ZIP codes

    @Test func zipPlusFourMatchesTheFiveDigitZip() {
        #expect(PostalAddressNormalizer.normalizedZip("11229-4121") == "11229")
        #expect(
            PostalAddressNormalizer.normalizedZip("11229")
                == PostalAddressNormalizer.normalizedZip("11229-4121")
        )
    }

    @Test func zipIgnoresSurroundingNoiseAndMissingValues() {
        #expect(PostalAddressNormalizer.normalizedZip(" 11229 ") == "11229")
        #expect(PostalAddressNormalizer.normalizedZip(nil).isEmpty)
        #expect(PostalAddressNormalizer.normalizedZip("").isEmpty)
    }

    @Test func differentZipsStillDiffer() {
        #expect(
            PostalAddressNormalizer.normalizedZip("11229-2510")
                != PostalAddressNormalizer.normalizedZip("11230-2510")
        )
    }

    // MARK: - DonorAddress uses the same rules

    @Test func donorAddressTreatsAbbreviationDifferencesAsTheSameAddress() {
        let stored = DonorAddress(
            street: "10 ROOSEVELT AVE",
            city: "Brooklyn",
            state: "NY",
            zip: "11229"
        )
        let retyped = DonorAddress(
            street: "10 Roosevelt Avenue",
            city: "brooklyn",
            state: "ny",
            zip: "11229-4121"
        )

        #expect(stored.matches(retyped))
    }

    @Test func donorAddressStillDetectsARealMove() {
        let before = DonorAddress(street: "2277 Homecrest Ave", city: "Brooklyn", zip: "11229")
        let after = DonorAddress(street: "1785 E 27th St", city: "Brooklyn", zip: "11229")

        #expect(!before.matches(after))
    }

    @Test func donorAddressDetectsAClearedSuite() {
        let withSuite = DonorAddress(street: "2277 Homecrest Ave", suite: "6G")
        let withoutSuite = DonorAddress(street: "2277 Homecrest Ave")

        #expect(!withSuite.matches(withoutSuite))
    }

    private func normalized(_ value: String?) -> String {
        PostalAddressNormalizer.normalized(value)
    }
}
