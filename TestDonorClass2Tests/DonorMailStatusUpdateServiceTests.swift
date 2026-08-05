//
//  DonorMailStatusUpdateServiceTests.swift
//  TestDonorClass2Tests
//

import Testing
@testable import TestDonorClass2

struct DonorMailStatusUpdateServiceTests {

    private let service = DonorMailStatusUpdateService()

    private func donor(mailStatus: DonorMailStatus) -> Donor {
        Donor(
            firstName: "Rose",
            lastName: "Simon",
            address: "7483 Pershing Avenue",
            suite: "4B",
            city: "Saint Louis",
            state: "MO",
            zip: "63130-4021",
            mailStatus: mailStatus.rawValue
        )
    }

    @Test func anActiveDonorIsFlagged() throws {
        let result = try #require(service.donorFlaggedAsBadAddress(donor(mailStatus: .active)))

        #expect(result.resolvedMailStatus == .badAddress)
    }

    @Test func flaggingLeavesTheAddressAsTheLastKnownAddress() throws {
        let stored = donor(mailStatus: .active)
        let result = try #require(service.donorFlaggedAsBadAddress(stored))

        #expect(result.address == "7483 Pershing Avenue")
        #expect(result.suite == "4B")
        #expect(result.city == "Saint Louis")
        #expect(result.zip == "63130-4021")
        #expect(result.priorAddress == nil)
    }

    @Test func anAlreadyFlaggedDonorNeedsNoChange() {
        #expect(service.donorFlaggedAsBadAddress(donor(mailStatus: .badAddress)) == nil)
    }

    /// Do Not Mail and Deceased describe the person, so a bad address must not
    /// quietly downgrade them.
    @Test func donorLevelSuppressionsAreNeverDowngraded() {
        for suppressed in [DonorMailStatus.doNotMail, .deceased] {
            #expect(service.donorFlaggedAsBadAddress(donor(mailStatus: suppressed)) == nil)
        }
    }

    @Test func aFlaggedDonorIsNoLongerEligibleForPostalMail() throws {
        let result = try #require(service.donorFlaggedAsBadAddress(donor(mailStatus: .active)))

        #expect(!result.allowsPostalMail)
    }
}
