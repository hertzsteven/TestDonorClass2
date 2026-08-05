//
//  NCOAImportServiceTests.swift
//  TestDonorClass2Tests
//

import Foundation
import Testing
@testable import TestDonorClass2

struct NCOAImportServiceTests {

    // MARK: - Fixtures

    /// Mirrors a real row: a donor in an apartment moving to a house.
    private static let oldAddress = DonorAddress(
        street: "2277 Homecrest Ave",
        suite: "6G",
        city: "Brooklyn",
        state: "NY",
        zip: "11229-4121"
    )

    private static let newAddress = DonorAddress(
        street: "1785 E 27th St",
        city: "Brooklyn",
        state: "NY",
        zip: "11229-2510"
    )

    private func donor(
        id: Int = 2755,
        address: DonorAddress = NCOAImportServiceTests.oldAddress,
        mailStatus: DonorMailStatus = .active
    ) -> Donor {
        var donor = Donor(
            firstName: "Yaakov",
            lastName: "Blau",
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
        donorId: Int = 2755,
        oldAddress: DonorAddress = NCOAImportServiceTests.oldAddress,
        newAddress: DonorAddress = NCOAImportServiceTests.newAddress
    ) -> NCOARecord {
        NCOARecord(
            donorId: donorId,
            firstName: "Yaakov",
            lastName: "Blau",
            company: "",
            newAddress: newAddress,
            oldAddress: oldAddress,
            moveType: .family,
            moveDate: Date()
        )
    }

    private func service(donors: [Donor]) -> (NCOAImportService, MockDonorRepository) {
        let repository = MockDonorRepository(donors: donors)
        return (NCOAImportService(repository: repository), repository)
    }

    // MARK: - Outcome: will update

    @Test func verifiedOldAddressIsMarkedForUpdate() async throws {
        let (service, _) = service(donors: [donor()])

        let items = try await service.buildPreview(for: [record()])

        #expect(items.count == 1)
        #expect(items[0].outcome == .willUpdate)
        #expect(items[0].storedDonorName == "Yaakov Blau")
    }

    @Test func formattingDifferencesDoNotBlockAVerifiedUpdate() async throws {
        let onFile = DonorAddress(
            street: "2277 HOMECREST AVENUE",
            suite: "# 6G",
            city: "brooklyn",
            state: "ny",
            zip: "11229"
        )
        let (service, _) = service(donors: [donor(address: onFile)])

        let items = try await service.buildPreview(for: [record()])

        #expect(items[0].outcome == .willUpdate)
    }

    // MARK: - Outcome: already current

    @Test func donorAlreadyAtTheNewAddressIsSkipped() async throws {
        let (service, _) = service(donors: [donor(address: Self.newAddress)])

        let items = try await service.buildPreview(for: [record()])

        #expect(items[0].outcome == .alreadyCurrent)
    }

    // MARK: - Outcome: donor not found

    @Test func unknownDonorIdIsReportedNotGuessed() async throws {
        let (service, _) = service(donors: [donor(id: 2755)])

        let items = try await service.buildPreview(for: [record(donorId: 35027)])

        #expect(items[0].outcome == .donorNotFound)
        #expect(items[0].currentAddress == nil)
        #expect(items[0].storedDonorName == nil)
    }

    // MARK: - Outcome: needs review

    @Test func addressMatchingNeitherSideIsLeftForReview() async throws {
        let unrelated = DonorAddress(
            street: "1442 45th St",
            city: "Brooklyn",
            state: "NY",
            zip: "11219"
        )
        let (service, _) = service(donors: [donor(address: unrelated)])

        let items = try await service.buildPreview(for: [record()])

        #expect(items[0].outcome == .needsReview)
        #expect(items[0].currentAddress?.street == "1442 45th St")
    }

    @Test func aDifferentHouseNumberOnTheSameStreetNeedsReview() async throws {
        var nearMiss = Self.oldAddress
        nearMiss.street = "2279 Homecrest Ave"
        let (service, _) = service(donors: [donor(address: nearMiss)])

        let items = try await service.buildPreview(for: [record()])

        #expect(items[0].outcome == .needsReview)
    }

    // MARK: - Apply

    @Test func applyWritesTheNewAddress() async throws {
        let (service, repository) = service(donors: [donor()])
        let items = try await service.buildPreview(for: [record()])

        let result = try await service.apply(items)

        #expect(result.updatedCount == 1)
        #expect(result.revalidationFailureCount == 0)

        let saved = try #require(await repository.getDonorById(2755))
        #expect(saved.address == "1785 E 27th St")
        #expect(saved.city == "Brooklyn")
        #expect(saved.zip == "11229-2510")
    }

    /// The apartment belonged to the old building, so it must not survive.
    @Test func applyClearsASuiteTheNewAddressDoesNotHave() async throws {
        let (service, repository) = service(donors: [donor()])
        let items = try await service.buildPreview(for: [record()])

        _ = try await service.apply(items)

        let saved = try #require(await repository.getDonorById(2755))
        #expect(saved.suite == nil)
        #expect(saved.addl_line == nil)
    }

    @Test func applyKeepsASuiteTheNewAddressDoesHave() async throws {
        let newWithSuite = DonorAddress(
            street: "1 Clinton Path",
            suite: "Apt 3",
            city: "Brookline",
            state: "MA",
            zip: "02445"
        )
        let (service, repository) = service(donors: [donor()])
        let items = try await service.buildPreview(for: [record(newAddress: newWithSuite)])

        _ = try await service.apply(items)

        let saved = try #require(await repository.getDonorById(2755))
        #expect(saved.suite == "Apt 3")
    }

    @Test func applySnapshotsThePriorAddress() async throws {
        let (service, repository) = service(donors: [donor()])
        let items = try await service.buildPreview(for: [record()])

        _ = try await service.apply(items)

        let saved = try #require(await repository.getDonorById(2755))
        #expect(saved.priorAddress?.street == "2277 Homecrest Ave")
        #expect(saved.priorAddress?.suite == "6G")
        #expect(saved.priorAddress?.zip == "11229-4121")
    }

    @Test func applyReactivatesADonorFlaggedWithABadAddress() async throws {
        let (service, repository) = service(donors: [donor(mailStatus: .badAddress)])
        let items = try await service.buildPreview(for: [record()])

        _ = try await service.apply(items)

        let saved = try #require(await repository.getDonorById(2755))
        #expect(saved.resolvedMailStatus == .active)
    }

    @Test func applyPreservesDonorLevelSuppressions() async throws {
        for suppressed in [DonorMailStatus.doNotMail, .deceased] {
            let (service, repository) = service(donors: [donor(mailStatus: suppressed)])
            let items = try await service.buildPreview(for: [record()])

            _ = try await service.apply(items)

            let saved = try #require(await repository.getDonorById(2755))
            #expect(saved.resolvedMailStatus == suppressed)
        }
    }

    // MARK: - Apply touches nothing it should not

    @Test func applyIgnoresEveryOutcomeExceptWillUpdate() async throws {
        let reviewable = donor(id: 1, address: DonorAddress(street: "1442 45th St"))
        let current = donor(id: 2, address: Self.newAddress)
        let (service, repository) = service(donors: [reviewable, current])

        let items = try await service.buildPreview(for: [
            record(donorId: 1),
            record(donorId: 2),
            record(donorId: 999)
        ])
        let result = try await service.apply(items)

        #expect(result.updatedCount == 0)

        let untouched = try #require(await repository.getDonorById(1))
        #expect(untouched.address == "1442 45th St")
        #expect(untouched.priorAddress == nil)
    }

    // MARK: - Idempotency

    @Test func importingTheSameFileTwiceChangesNothingTheSecondTime() async throws {
        let (service, repository) = service(donors: [donor()])
        let records = [record()]

        let firstPreview = try await service.buildPreview(for: records)
        let firstResult = try await service.apply(firstPreview)
        #expect(firstResult.updatedCount == 1)

        let secondPreview = try await service.buildPreview(for: records)
        #expect(secondPreview[0].outcome == .alreadyCurrent)

        let secondResult = try await service.apply(secondPreview)
        #expect(secondResult.updatedCount == 0)

        // The genuine prior address survives, rather than being overwritten
        // with the new address by a second pass.
        let saved = try #require(await repository.getDonorById(2755))
        #expect(saved.priorAddress?.street == "2277 Homecrest Ave")
    }

    // MARK: - Revalidation

    @Test func aDonorEditedAfterThePreviewIsLeftAlone() async throws {
        let (service, repository) = service(donors: [donor()])
        let items = try await service.buildPreview(for: [record()])
        #expect(items[0].outcome == .willUpdate)

        // Someone edits the address between the preview and the apply.
        var edited = donor()
        edited.address = "1 Somewhere Else"
        try await repository.update(edited)

        let result = try await service.apply(items)

        #expect(result.updatedCount == 0)
        #expect(result.revalidationFailureCount == 1)

        let saved = try #require(await repository.getDonorById(2755))
        #expect(saved.address == "1 Somewhere Else")
    }

    // MARK: - Summary

    @Test func summaryCountsEachOutcome() async throws {
        let donors = [
            donor(id: 1),
            donor(id: 2),
            donor(id: 3, address: Self.newAddress),
            donor(id: 4, address: DonorAddress(street: "1442 45th St"))
        ]
        let (service, _) = service(donors: donors)

        let items = try await service.buildPreview(for: [
            record(donorId: 1),
            record(donorId: 2),
            record(donorId: 3),
            record(donorId: 4),
            record(donorId: 999)
        ])
        let summary = NCOAImportSummary(items: items)

        #expect(summary.count(of: .willUpdate) == 2)
        #expect(summary.count(of: .alreadyCurrent) == 1)
        #expect(summary.count(of: .needsReview) == 1)
        #expect(summary.count(of: .donorNotFound) == 1)
        #expect(summary.applyableCount == 2)
        #expect(summary.totalCount == 5)
    }
}
