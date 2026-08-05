//
//  ExternalDonationImportServiceTests.swift
//  TestDonorClass2Tests
//

import Foundation
import Testing
@testable import TestDonorClass2

struct ExternalDonationImportServiceTests {

    private let calendar = Calendar(identifier: .gregorian)

    private func makeService(
        donors: [Donor] = [],
        donations: [Donation] = []
    ) -> (
        ExternalDonationImportService,
        MockDonorRepository,
        MockDonationRepository,
        MockExternalDonationImportRepository
    ) {
        let donorRepo = MockDonorRepository(donors: donors)
        let donationRepo = MockDonationRepository(donations: donations)
        let importRepo = MockExternalDonationImportRepository(
            donorRepository: donorRepo,
            donationRepository: donationRepo
        )
        let service = ExternalDonationImportService(
            donorRepository: donorRepo,
            donationRepository: donationRepo,
            importRepository: importRepo,
            calendar: calendar
        )
        return (service, donorRepo, donationRepo, importRepo)
    }

    private func record(
        row: Int = 2,
        source: ExternalDonationSource = .zelle,
        reference: String? = "R-\(Int.random(in: 1...99999))",
        first: String? = "Malka",
        last: String? = "Steinmetz",
        org: String? = nil,
        amount: Double = 5,
        date: Date? = nil,
        reviewNeeded: String? = nil
    ) -> ExternalDonationRecord {
        let day = date ?? calendar.date(from: DateComponents(year: 2026, month: 5, day: 29))!
        return ExternalDonationRecord(
            rowNumber: row,
            referenceNumber: reference,
            source: source,
            date: day,
            amount: amount,
            firstName: first,
            lastName: last,
            organizationName: org,
            address: DonorAddress(),
            email: nil,
            phone: nil,
            memo: nil,
            hebrewName: nil,
            mothersHebrewName: nil,
            details: nil,
            product: nil,
            messageID: nil,
            reviewNeeded: reviewNeeded
        )
    }

    private func donor(id: Int, first: String, last: String) -> Donor {
        var donor = Donor(firstName: first, lastName: last)
        donor.id = id
        return donor
    }

    // MARK: - Classification

    @Test func alreadyImportedWhenKeyExists() async throws {
        let rec = record(source: .ojc, reference: "CERT-1")
        let existing = Donation(
            donorId: 1,
            amount: 5,
            donationType: .organizationDirect,
            transactionNumber: rec.importKey
        )
        let (service, _, _, _) = makeService(
            donors: [donor(id: 1, first: "Malka", last: "Steinmetz")],
            donations: [existing]
        )

        let items = try await service.buildPreview(for: [rec])
        #expect(items[0].outcome == .alreadyImported)
        #expect(items[0].decision == .skip)
    }

    @Test func likelyMatchNeedsDecision() async throws {
        let (service, _, _, _) = makeService(
            donors: [donor(id: 7, first: "Malka", last: "Steinmetz")]
        )

        let items = try await service.buildPreview(for: [record()])
        #expect(items[0].outcome == .likelyMatch)
        #expect(items[0].decision == .pending)
        #expect(items[0].candidates.count == 1)
    }

    @Test func needsChoiceWhenMultipleLastNames() async throws {
        let (service, _, _, _) = makeService(
            donors: [
                donor(id: 1, first: "A", last: "Cohen"),
                donor(id: 2, first: "B", last: "Cohen")
            ]
        )

        let items = try await service.buildPreview(
            for: [record(first: "C", last: "Cohen")]
        )
        #expect(items[0].outcome == .needsChoice)
        #expect(items[0].candidates.count == 2)
    }

    @Test func newDonorWhenNoMatch() async throws {
        let (service, _, _, _) = makeService(donors: [donor(id: 1, first: "Other", last: "Person")])
        let items = try await service.buildPreview(for: [record()])
        #expect(items[0].outcome == .newDonor)
        #expect(items[0].decision == .createNew)
    }

    @Test func unidentifiedGoesAnonymous() async throws {
        let (service, _, _, _) = makeService()
        let items = try await service.buildPreview(
            for: [record(first: "Anonymous", last: nil, org: nil)]
        )
        #expect(items[0].outcome == .unidentified)
        #expect(items[0].decision == .anonymous)
    }

    @Test func reviewNeededForcesManualReview() async throws {
        let (service, _, _, _) = makeService(
            donors: [donor(id: 7, first: "Malka", last: "Steinmetz")]
        )
        let items = try await service.buildPreview(
            for: [record(reviewNeeded: "verify this")]
        )
        #expect(items[0].outcome == .forcedReview)
        #expect(items[0].decision == .pending)
    }

    @Test func donorsFundAttachesToHoldingDonor() async throws {
        var fund = Donor(company: "The Donors Fund")
        fund.id = 99
        let (service, _, _, _) = makeService(donors: [fund])

        let items = try await service.buildPreview(
            for: [record(source: .donorsFund, first: nil, last: nil, org: "Someone")]
        )
        #expect(items[0].outcome == .likelyMatch)
        #expect(items[0].decision == .attach(donorId: 99))
    }

    @Test func suspectedDuplicateSkips() async throws {
        let day = calendar.date(from: DateComponents(year: 2026, month: 5, day: 29))!
        let existing = Donation(
            donorId: 7,
            amount: 5,
            donationType: .zelle,
            paymentStatus: .completed,
            donationDate: day
        )
        let (service, _, _, _) = makeService(
            donors: [donor(id: 7, first: "Malka", last: "Steinmetz")],
            donations: [existing]
        )

        let items = try await service.buildPreview(for: [record(amount: 5, date: day)])
        #expect(items[0].outcome == .suspectedDuplicate)
        #expect(items[0].decision == .skip)
    }

    // MARK: - Apply

    @Test func applyCreatesNewDonorAndDonation() async throws {
        let (service, donorRepo, donationRepo, _) = makeService()
        var items = try await service.buildPreview(for: [record(reference: "NEW-1")])
        #expect(items[0].outcome == .newDonor)

        let result = try await service.apply(items, campaignId: nil)
        #expect(result.donorsCreated == 1)
        #expect(result.donationsCreated == 1)
        #expect(try await donorRepo.getCount() == 1)
        #expect(try await donationRepo.getCount() == 1)

        let donation = try #require(donationRepo.allDonations.first)
        #expect(donation.transactionNumber == "ZELLE#NEW-1")
        #expect(donation.donationType == .zelle)
        #expect(donation.receiptStatus == .digitallySent)
    }

    @Test func applyAttachesConfirmedMatch() async throws {
        let (service, _, donationRepo, _) = makeService(
            donors: [donor(id: 7, first: "Malka", last: "Steinmetz")]
        )
        var items = try await service.buildPreview(for: [record(reference: "ATT-1")])
        items[0].decision = .attach(donorId: 7)

        let result = try await service.apply(items, campaignId: 3)
        #expect(result.donorsCreated == 0)
        #expect(result.donationsCreated == 1)
        #expect(donationRepo.allDonations.first?.donorId == 7)
        #expect(donationRepo.allDonations.first?.campaignId == 3)
    }

    @Test func applySkipsAlreadyImportedRows() async throws {
        let rec = record(reference: "DUPKEY")
        let existing = Donation(
            donorId: 1,
            amount: 5,
            donationType: .zelle,
            transactionNumber: rec.importKey
        )
        let (service, _, donationRepo, _) = makeService(
            donors: [donor(id: 1, first: "Malka", last: "Steinmetz")],
            donations: [existing]
        )

        let items = try await service.buildPreview(for: [rec])
        #expect(items[0].outcome == .alreadyImported)

        let result = try await service.apply(items, campaignId: nil)
        #expect(result.donationsCreated == 0)
        #expect(result.skippedCount == 1)
        #expect(donationRepo.allDonations.count == 1)
    }

    @Test func applyDetectsKeyInsertedBetweenPreviewAndApply() async throws {
        let (service, _, donationRepo, _) = makeService(
            donors: [donor(id: 7, first: "Malka", last: "Steinmetz")]
        )
        var items = try await service.buildPreview(for: [record(reference: "RACE-1")])
        items[0].decision = .attach(donorId: 7)

        _ = try await donationRepo.insert(
            Donation(
                donorId: 7,
                amount: 5,
                donationType: .zelle,
                transactionNumber: items[0].record.importKey
            )
        )

        let result = try await service.apply(items, campaignId: nil)
        #expect(result.donationsCreated == 0)
        #expect(result.revalidationFailureCount == 1)
        #expect(donationRepo.allDonations.count == 1)
    }
}
