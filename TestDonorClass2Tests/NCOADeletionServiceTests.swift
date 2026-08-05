//
//  NCOADeletionServiceTests.swift
//  TestDonorClass2Tests
//

import Foundation
import Testing
@testable import TestDonorClass2

struct NCOADeletionServiceTests {

    // MARK: - Fixtures

    /// Mirrors a real row from the delete file.
    private static let undeliverable = DonorAddress(
        street: "19 Cardinal Rd",
        city: "Worcester",
        state: "MA",
        zip: "01602-1765"
    )

    private func donor(
        id: Int = 233,
        address: DonorAddress = NCOADeletionServiceTests.undeliverable,
        mailStatus: DonorMailStatus = .active
    ) -> Donor {
        var donor = Donor(
            firstName: "Nason Arthur",
            lastName: "Hurowitz",
            address: address.street,
            addl_line: address.additionalLine,
            suite: address.suite,
            city: address.city,
            state: address.state,
            zip: address.zip,
            mailStatus: mailStatus.rawValue
        )
        donor.id = id
        return donor
    }

    private func record(
        donorId: Int = 233,
        oldAddress: DonorAddress = NCOADeletionServiceTests.undeliverable
    ) -> NCOADeletionRecord {
        NCOADeletionRecord(
            donorId: donorId,
            firstName: "Nason Arthur",
            lastName: "Hurowitz",
            company: "",
            reason: "Moved No Forwarding Address",
            oldAddress: oldAddress
        )
    }

    private func service(donors: [Donor]) -> (NCOADeletionService, MockDonorRepository) {
        let repository = MockDonorRepository(donors: donors)
        return (NCOADeletionService(repository: repository), repository)
    }

    // MARK: - Outcome: will flag

    @Test func verifiedUndeliverableAddressIsMarkedForFlagging() async throws {
        let (service, _) = service(donors: [donor()])

        let items = try await service.buildPreview(for: [record()])

        #expect(items.count == 1)
        #expect(items[0].outcome == .willFlag)
        #expect(items[0].storedDonorName == "Nason Arthur Hurowitz")
        #expect(items[0].currentMailStatus == .active)
    }

    @Test func formattingDifferencesDoNotBlockAVerifiedFlag() async throws {
        let onFile = DonorAddress(
            street: "19 CARDINAL ROAD",
            city: "worcester",
            state: "ma",
            zip: "01602"
        )
        let (service, _) = service(donors: [donor(address: onFile)])

        let items = try await service.buildPreview(for: [record()])

        #expect(items[0].outcome == .willFlag)
    }

    // MARK: - Outcome: already flagged or suppressed

    @Test func anAlreadyFlaggedDonorIsSkipped() async throws {
        let (service, _) = service(donors: [donor(mailStatus: .badAddress)])

        let items = try await service.buildPreview(for: [record()])

        #expect(items[0].outcome == .alreadyFlagged)
    }

    @Test func aSuppressedDonorIsSkippedRatherThanDowngraded() async throws {
        for suppressed in [DonorMailStatus.doNotMail, .deceased] {
            let (service, _) = service(donors: [donor(mailStatus: suppressed)])

            let items = try await service.buildPreview(for: [record()])

            #expect(items[0].outcome == .alreadySuppressed)
            #expect(items[0].currentMailStatus == suppressed)
        }
    }

    // MARK: - Outcome: donor not found

    @Test func unknownDonorIdIsReportedNotGuessed() async throws {
        let (service, _) = service(donors: [donor(id: 233)])

        let items = try await service.buildPreview(for: [record(donorId: 99999)])

        #expect(items[0].outcome == .donorNotFound)
        #expect(items[0].currentAddress == nil)
        #expect(items[0].currentMailStatus == nil)
    }

    // MARK: - Outcome: needs review

    @Test func aDonorWhoHasSinceMovedNeedsReview() async throws {
        let newer = DonorAddress(
            street: "1785 E 27th St",
            city: "Brooklyn",
            state: "NY",
            zip: "11229"
        )
        let (service, _) = service(donors: [donor(address: newer)])

        let items = try await service.buildPreview(for: [record()])

        #expect(items[0].outcome == .needsReview)
    }

    /// A mismatch outranks the status check, so a stale row cannot flag a donor
    /// just because the donor happens to be active.
    @Test func mismatchIsReportedEvenForAnActiveDonor() async throws {
        let (service, repository) = service(
            donors: [donor(address: DonorAddress(street: "1 Somewhere Else"), mailStatus: .active)]
        )

        let items = try await service.buildPreview(for: [record()])
        _ = try await service.apply(items)

        let saved = try #require(await repository.getDonorById(233))
        #expect(saved.resolvedMailStatus == .active)
    }

    // MARK: - Apply

    @Test func applyFlagsTheDonorAsBadAddress() async throws {
        let (service, repository) = service(donors: [donor()])
        let items = try await service.buildPreview(for: [record()])

        let result = try await service.apply(items)

        #expect(result.updatedCount == 1)
        #expect(result.revalidationFailureCount == 0)

        let saved = try #require(await repository.getDonorById(233))
        #expect(saved.resolvedMailStatus == .badAddress)
        #expect(!saved.allowsPostalMail)
    }

    /// The address is the last known address and the verification key for a
    /// later import, so it must survive.
    @Test func applyLeavesTheAddressUntouched() async throws {
        let withSuite = DonorAddress(
            street: "40 Berkeley St",
            suite: "# 323",
            city: "Boston",
            state: "MA",
            zip: "02116-6316"
        )
        let (service, repository) = service(donors: [donor(address: withSuite)])
        let items = try await service.buildPreview(for: [record(oldAddress: withSuite)])

        _ = try await service.apply(items)

        let saved = try #require(await repository.getDonorById(233))
        #expect(saved.address == "40 Berkeley St")
        #expect(saved.suite == "# 323")
        #expect(saved.city == "Boston")
        #expect(saved.zip == "02116-6316")
        #expect(saved.priorAddress == nil)
    }

    @Test func applyIgnoresEveryOutcomeExceptWillFlag() async throws {
        let donors = [
            donor(id: 1, address: DonorAddress(street: "1 Somewhere Else")),
            donor(id: 2, mailStatus: .badAddress),
            donor(id: 3, mailStatus: .deceased)
        ]
        let (service, repository) = service(donors: donors)

        let items = try await service.buildPreview(for: [
            record(donorId: 1),
            record(donorId: 2),
            record(donorId: 3),
            record(donorId: 99999)
        ])
        let result = try await service.apply(items)

        #expect(result.updatedCount == 0)
        #expect(try #require(await repository.getDonorById(1)).resolvedMailStatus == .active)
        #expect(try #require(await repository.getDonorById(3)).resolvedMailStatus == .deceased)
    }

    // MARK: - Idempotency

    @Test func importingTheSameFileTwiceChangesNothingTheSecondTime() async throws {
        let (service, _) = service(donors: [donor()])
        let records = [record()]

        let firstPreview = try await service.buildPreview(for: records)
        let firstResult = try await service.apply(firstPreview)
        #expect(firstResult.updatedCount == 1)

        let secondPreview = try await service.buildPreview(for: records)
        #expect(secondPreview[0].outcome == .alreadyFlagged)

        let secondResult = try await service.apply(secondPreview)
        #expect(secondResult.updatedCount == 0)
    }

    // MARK: - Revalidation

    @Test func aDonorEditedAfterThePreviewIsLeftAlone() async throws {
        let (service, repository) = service(donors: [donor()])
        let items = try await service.buildPreview(for: [record()])
        #expect(items[0].outcome == .willFlag)

        // The address is corrected between the preview and the apply.
        var edited = donor()
        edited.address = "1 Somewhere Else"
        try await repository.update(edited)

        let result = try await service.apply(items)

        #expect(result.updatedCount == 0)
        #expect(result.revalidationFailureCount == 1)
        #expect(try #require(await repository.getDonorById(233)).resolvedMailStatus == .active)
    }

    // MARK: - Reactivation

    /// A flag is not a dead end: a later address change clears it, which is what
    /// the address update service already does on a move.
    @Test func aLaterAddressChangeClearsTheFlag() async throws {
        let (service, repository) = service(donors: [donor()])
        let items = try await service.buildPreview(for: [record()])
        _ = try await service.apply(items)

        let flagged = try #require(await repository.getDonorById(233))
        #expect(flagged.resolvedMailStatus == .badAddress)

        var moved = flagged
        moved.currentAddress = DonorAddress(
            street: "1785 E 27th St",
            city: "Brooklyn",
            state: "NY",
            zip: "11229"
        )
        let reactivated = DonorAddressUpdateService().donorForSaving(edited: moved, stored: flagged)

        #expect(reactivated.resolvedMailStatus == .active)
        #expect(reactivated.priorAddress?.street == "19 Cardinal Rd")
    }

    // MARK: - Summary

    @Test func summaryCountsEachOutcome() async throws {
        let donors = [
            donor(id: 1),
            donor(id: 2),
            donor(id: 3, mailStatus: .badAddress),
            donor(id: 4, mailStatus: .doNotMail),
            donor(id: 5, address: DonorAddress(street: "1 Somewhere Else"))
        ]
        let (service, _) = service(donors: donors)

        let items = try await service.buildPreview(for: (1...6).map { record(donorId: $0 == 6 ? 99999 : $0) })
        let summary = NCOADeletionSummary(items: items)

        #expect(summary.count(of: .willFlag) == 2)
        #expect(summary.count(of: .alreadyFlagged) == 1)
        #expect(summary.count(of: .alreadySuppressed) == 1)
        #expect(summary.count(of: .needsReview) == 1)
        #expect(summary.count(of: .donorNotFound) == 1)
        #expect(summary.applyableCount == 2)
        #expect(summary.totalCount == 6)
    }
}
