//
//  DonorAddressUpdateServiceTests.swift
//  TestDonorClass2Tests
//

import Testing
@testable import TestDonorClass2

struct DonorAddressUpdateServiceTests {

    private let service = DonorAddressUpdateService()

    private func donor(
        street: String? = "1442 45th St",
        suite: String? = nil,
        additionalLine: String? = nil,
        city: String? = "Brooklyn",
        state: String? = "NY",
        zip: String? = "11219",
        mailStatus: DonorMailStatus = .active
    ) -> Donor {
        Donor(
            firstName: "Ada",
            lastName: "Lovelace",
            address: street,
            addl_line: additionalLine,
            suite: suite,
            city: city,
            state: state,
            zip: zip,
            mailStatus: mailStatus.rawValue
        )
    }

    // MARK: - No change

    @Test func unchangedAddressLeavesRecordAlone() {
        let stored = donor()
        let result = service.donorForSaving(edited: stored, stored: stored)

        #expect(result.priorAddress == nil)
        #expect(result.currentAddress.matches(stored.currentAddress))
    }

    @Test func casingAndWhitespaceAreNotTreatedAsAMove() {
        let stored = donor(street: "1442 45th St", city: "Brooklyn")
        var edited = stored
        edited.address = "  1442 45TH st "
        edited.city = "BROOKLYN"

        let result = service.donorForSaving(edited: edited, stored: stored)

        #expect(result.priorAddress == nil)
    }

    @Test func unchangedAddressDoesNotClearBadAddressFlag() {
        let stored = donor(mailStatus: .badAddress)
        let result = service.donorForSaving(edited: stored, stored: stored)

        #expect(result.resolvedMailStatus == .badAddress)
    }

    // MARK: - Address changed

    @Test func changedStreetSnapshotsTheOldAddress() {
        let stored = donor(street: "1442 45th St")
        var edited = stored
        edited.address = "78 Ocean Parkway"

        let result = service.donorForSaving(edited: edited, stored: stored)

        #expect(result.priorAddress?.street == "1442 45th St")
        #expect(result.priorAddress?.city == "Brooklyn")
        #expect(result.priorAddress?.zip == "11219")
        #expect(result.address == "78 Ocean Parkway")
    }

    @Test func changingOnlyZipStillCountsAsAMove() {
        let stored = donor(zip: "11219")
        var edited = stored
        edited.zip = "11230"

        let result = service.donorForSaving(edited: edited, stored: stored)

        #expect(result.priorAddress?.zip == "11219")
        #expect(result.zip == "11230")
    }

    @Test func changingOnlySuiteStillCountsAsAMove() {
        let stored = donor(suite: "4B")
        var edited = stored
        edited.suite = "5C"

        let result = service.donorForSaving(edited: edited, stored: stored)

        #expect(result.priorAddress?.suite == "4B")
    }

    // MARK: - Mail status transitions

    @Test func moveClearsBadAddress() {
        let stored = donor(mailStatus: .badAddress)
        var edited = stored
        edited.address = "78 Ocean Parkway"

        let result = service.donorForSaving(edited: edited, stored: stored)

        #expect(result.resolvedMailStatus == .active)
    }

    @Test func movePreservesDonorLevelSuppressions() {
        for suppressed in [DonorMailStatus.doNotMail, .deceased] {
            let stored = donor(mailStatus: suppressed)
            var edited = stored
            edited.address = "78 Ocean Parkway"

            let result = service.donorForSaving(edited: edited, stored: stored)

            #expect(result.resolvedMailStatus == suppressed)
        }
    }

    // MARK: - Snapshot replacement

    @Test func secondMoveReplacesTheEarlierSnapshot() {
        let original = donor(street: "1442 45th St")

        var secondEdit = original
        secondEdit.address = "78 Ocean Parkway"
        let afterFirstMove = service.donorForSaving(edited: secondEdit, stored: original)
        #expect(afterFirstMove.priorAddress?.street == "1442 45th St")

        var thirdEdit = afterFirstMove
        thirdEdit.address = "1 Main St"
        let afterSecondMove = service.donorForSaving(edited: thirdEdit, stored: afterFirstMove)

        #expect(afterSecondMove.priorAddress?.street == "78 Ocean Parkway")
        #expect(afterSecondMove.address == "1 Main St")
    }

    @Test func blankPreviousAddressDoesNotOverwriteAnExistingSnapshot() {
        var stored = donor(street: nil, city: nil, state: nil, zip: nil)
        stored.priorAddress = DonorAddress(street: "1442 45th St", city: "Brooklyn")

        var edited = stored
        edited.address = "78 Ocean Parkway"

        let result = service.donorForSaving(edited: edited, stored: stored)

        #expect(result.priorAddress?.street == "1442 45th St")
    }

    // MARK: - DonorAddress helpers

    @Test func priorAddressIsNilWhenNoSnapshotStored() {
        #expect(donor().priorAddress == nil)
    }

    @Test func displayLinesCombineStreetAndCityStateZip() {
        let address = DonorAddress(
            street: "1442 45th St",
            suite: "4B",
            city: "Brooklyn",
            state: "NY",
            zip: "11219"
        )

        #expect(address.displayLines == ["1442 45th St, Apt/Ste 4B", "Brooklyn NY 11219"])
    }

    @Test func emptyAddressReportsEmpty() {
        #expect(DonorAddress().isEmpty)
        #expect(DonorAddress(street: "   ", city: "\n").isEmpty)
        #expect(!DonorAddress(zip: "11219").isEmpty)
    }
}
