//
//  ExternalDonationImportRepository.swift
//  TestDonorClass2
//
//  Writes new donors and their donations in one transaction so a mid-way
//  failure leaves nothing half-applied.
//

import Foundation
import GRDB

/// One unit of work for the external-donation apply step.
enum ExternalDonationImportAction {
    /// Create a donor, then a donation attached to that new id.
    case createDonorAndDonation(Donor, Donation)

    /// Create a donation on an existing donor id.
    case createDonation(Donation)
}

protocol ExternalDonationImportRepositoryProtocol {
    func apply(_ actions: [ExternalDonationImportAction]) async throws -> ExternalDonationApplyResult
}

struct ExternalDonationImportRepository: ExternalDonationImportRepositoryProtocol {
    private var dbPool: DatabasePool {
        get throws {
            try DatabaseManager.shared.getDbPool()
        }
    }

    init() {}

    func apply(_ actions: [ExternalDonationImportAction]) async throws -> ExternalDonationApplyResult {
        guard !actions.isEmpty else {
            return ExternalDonationApplyResult(
                donorsCreated: 0,
                donationsCreated: 0,
                skippedCount: 0,
                revalidationFailureCount: 0
            )
        }

        do {
            return try await dbPool.write { db in
                var donorsCreated = 0
                var donationsCreated = 0

                for action in actions {
                    switch action {
                    case .createDonorAndDonation(var donor, var donation):
                        try donor.insert(db)
                        donor.id = Int(db.lastInsertedRowID)
                        donorsCreated += 1

                        donation.donorId = donor.id
                        try donation.insert(db)
                        donationsCreated += 1

                    case .createDonation(var donation):
                        try donation.insert(db)
                        donationsCreated += 1
                    }
                }

                return ExternalDonationApplyResult(
                    donorsCreated: donorsCreated,
                    donationsCreated: donationsCreated,
                    skippedCount: 0,
                    revalidationFailureCount: 0
                )
            }
        } catch {
            throw RepositoryError.insertFailed(error.localizedDescription)
        }
    }
}
