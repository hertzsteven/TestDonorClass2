//
//  NCOADeletionService.swift
//  TestDonorClass2
//
//  Single responsibility: decide which undeliverable-address rows may safely
//  flag a donor, and carry out the ones that may. Reading and deciding are kept
//  apart from writing so the caller can show a preview first.
//

import Foundation

struct NCOADeletionService {

    private let repository: any DonorSpecificRepositoryProtocol
    private let mailStatusUpdateService: DonorMailStatusUpdateService

    init(
        repository: any DonorSpecificRepositoryProtocol,
        mailStatusUpdateService: DonorMailStatusUpdateService = DonorMailStatusUpdateService()
    ) {
        self.repository = repository
        self.mailStatusUpdateService = mailStatusUpdateService
    }

    init(mailStatusUpdateService: DonorMailStatusUpdateService = DonorMailStatusUpdateService()) throws {
        self.init(
            repository: try DonorRepository(),
            mailStatusUpdateService: mailStatusUpdateService
        )
    }

    // MARK: - Preview

    /// Classifies every row without writing anything.
    func buildPreview(for records: [NCOADeletionRecord]) async throws -> [NCOADeletionItem] {
        var items: [NCOADeletionItem] = []
        items.reserveCapacity(records.count)

        for record in records {
            let donor = try await repository.getDonorById(record.donorId)
            items.append(Self.item(for: record, donor: donor))
        }
        return items
    }

    /// The address on file must be the one reported undeliverable before the
    /// donor's status is considered at all.
    private static func item(for record: NCOADeletionRecord, donor: Donor?) -> NCOADeletionItem {
        guard let donor else {
            return NCOADeletionItem(
                record: record,
                outcome: .donorNotFound,
                currentAddress: nil,
                storedDonorName: nil,
                currentMailStatus: nil
            )
        }

        let onFile = donor.currentAddress
        let status = donor.resolvedMailStatus

        let outcome: NCOADeletionOutcome
        if !onFile.matches(record.oldAddress) {
            outcome = .needsReview
        } else {
            switch status {
            case .active: outcome = .willFlag
            case .badAddress: outcome = .alreadyFlagged
            case .doNotMail, .deceased: outcome = .alreadySuppressed
            }
        }

        return NCOADeletionItem(
            record: record,
            outcome: outcome,
            currentAddress: onFile,
            storedDonorName: Self.name(of: donor),
            currentMailStatus: status
        )
    }

    // MARK: - Apply

    /// Flags only the verified rows, re-checking each one against the database
    /// first in case a donor was edited after the preview was built.
    func apply(_ items: [NCOADeletionItem]) async throws -> NCOAApplyResult {
        let verified = items.filter(\.outcome.isApplied)
        guard !verified.isEmpty else {
            return NCOAApplyResult(updatedCount: 0, revalidationFailureCount: 0)
        }

        var updates: [Donor] = []
        var revalidationFailures = 0

        for item in verified {
            guard let stored = try await repository.getDonorById(item.record.donorId),
                  stored.currentAddress.matches(item.record.oldAddress),
                  let flagged = mailStatusUpdateService.donorFlaggedAsBadAddress(stored) else {
                revalidationFailures += 1
                continue
            }
            updates.append(flagged)
        }

        try await repository.updateBatch(updates)

        return NCOAApplyResult(
            updatedCount: updates.count,
            revalidationFailureCount: revalidationFailures
        )
    }

    private static func name(of donor: Donor) -> String {
        let personal = [donor.firstName, donor.lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard let company = donor.company?.trimmingCharacters(in: .whitespacesAndNewlines),
              !company.isEmpty else {
            return personal
        }
        return personal.isEmpty ? company : "\(personal) (\(company))"
    }
}
