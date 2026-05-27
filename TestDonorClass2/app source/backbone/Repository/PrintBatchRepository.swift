//
//  PrintBatchRepository.swift
//  TestDonorClass2
//
//  Persists print batches and coordinates batch-level revert operations.
//

import Foundation
import GRDB

final class PrintBatchRepository {
    private let injectedPool: DatabasePool?

    private var dbPool: DatabasePool {
        get throws {
            if let injectedPool {
                return injectedPool
            }
            return try DatabaseManager.shared.getDbPool()
        }
    }

    init(dbPool: DatabasePool? = nil) {
        self.injectedPool = dbPool
    }

    /// Creates a print batch and marks every donation as printed in a single transaction.
    func createBatch(donationIds: [Int], label: String?) async throws -> Int {
        guard !donationIds.isEmpty else {
            throw PrintBatchRepositoryError.emptyDonationList
        }

        return try await dbPool.write { db in
            let now = Date()
            var batch = PrintBatch(
                printedAt: now,
                receiptCount: donationIds.count,
                label: label,
                status: .printed
            )
            try batch.insert(db)
            let batchId = Int(db.lastInsertedRowID)

            for donationId in donationIds {
                try db.execute(
                    sql: """
                        UPDATE donation
                        SET receipt_status = ?, print_batch_id = ?, printed_at = ?
                        WHERE id = ?
                        """,
                    arguments: [
                        ReceiptStatus.printed.rawValue,
                        batchId,
                        now,
                        donationId,
                    ]
                )
            }

            return batchId
        }
    }

    /// Reverts every donation in the batch back to requested and marks the batch fully reverted.
    func revertBatch(batchId: Int) async throws {
        try await dbPool.write { db in
            try db.execute(
                sql: """
                    UPDATE donation
                    SET receipt_status = ?, print_batch_id = NULL, printed_at = NULL
                    WHERE print_batch_id = ?
                    """,
                arguments: [ReceiptStatus.requested.rawValue, batchId]
            )

            try db.execute(
                sql: """
                    UPDATE print_batch
                    SET status = ?
                    WHERE id = ?
                    """,
                arguments: [PrintBatchStatus.fullyReverted.rawValue, batchId]
            )
        }
    }

    func fetchBatch(id: Int) async throws -> PrintBatch? {
        try await dbPool.read { db in
            try PrintBatch.fetchOne(db, key: id)
        }
    }
}

enum PrintBatchRepositoryError: LocalizedError {
    case emptyDonationList

    var errorDescription: String? {
        switch self {
        case .emptyDonationList:
            return "Cannot create a print batch with no donations."
        }
    }
}
