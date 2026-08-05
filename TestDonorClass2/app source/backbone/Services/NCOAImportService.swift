//
//  NCOAImportService.swift
//  TestDonorClass2
//
//  Single responsibility: decide which NCOA rows may safely change a donor, and
//  carry out the ones that may. Reading and deciding are kept apart from
//  writing so the caller can show a preview before anything is persisted.
//

import Foundation

struct NCOAImportService {

    private let repository: any DonorSpecificRepositoryProtocol
    private let addressUpdateService: DonorAddressUpdateService

    init(
        repository: any DonorSpecificRepositoryProtocol,
        addressUpdateService: DonorAddressUpdateService = DonorAddressUpdateService()
    ) {
        self.repository = repository
        self.addressUpdateService = addressUpdateService
    }

    init(addressUpdateService: DonorAddressUpdateService = DonorAddressUpdateService()) throws {
        self.init(
            repository: try DonorRepository(),
            addressUpdateService: addressUpdateService
        )
    }

    // MARK: - Preview

    /// Classifies every row without writing anything.
    func buildPreview(for records: [NCOARecord]) async throws -> [NCOAImportItem] {
        var items: [NCOAImportItem] = []
        items.reserveCapacity(records.count)

        for record in records {
            let donor = try await repository.getDonorById(record.donorId)
            items.append(Self.item(for: record, donor: donor))
        }
        return items
    }

    /// The address on file decides the outcome. Checking for the new address
    /// first is what makes re-importing the same file a no-op instead of a
    /// second move that would discard the real prior address.
    private static func item(for record: NCOARecord, donor: Donor?) -> NCOAImportItem {
        guard let donor else {
            return NCOAImportItem(
                record: record,
                outcome: .donorNotFound,
                currentAddress: nil,
                storedDonorName: nil
            )
        }

        let onFile = donor.currentAddress
        let outcome: NCOAImportOutcome
        if onFile.matches(record.newAddress) {
            outcome = .alreadyCurrent
        } else if onFile.matches(record.oldAddress) {
            outcome = .willUpdate
        } else {
            outcome = .needsReview
        }

        return NCOAImportItem(
            record: record,
            outcome: outcome,
            currentAddress: onFile,
            storedDonorName: name(of: donor)
        )
    }

    // MARK: - Apply

    /// Writes only the verified rows, re-checking each one against the database
    /// first in case a donor was edited after the preview was built.
    func apply(_ items: [NCOAImportItem]) async throws -> NCOAApplyResult {
        let verified = items.filter(\.outcome.isApplied)
        guard !verified.isEmpty else {
            return NCOAApplyResult(updatedCount: 0, revalidationFailureCount: 0)
        }

        var updates: [Donor] = []
        var revalidationFailures = 0

        for item in verified {
            guard let stored = try await repository.getDonorById(item.record.donorId),
                  stored.currentAddress.matches(item.record.oldAddress) else {
                revalidationFailures += 1
                continue
            }

            var edited = stored
            // Assigning the whole address replaces every component, so a suite
            // that belonged to the old residence is cleared rather than carried
            // over to the new street.
            edited.currentAddress = item.record.newAddress

            updates.append(addressUpdateService.donorForSaving(edited: edited, stored: stored))
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
