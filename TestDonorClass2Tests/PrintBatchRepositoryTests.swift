//
//  PrintBatchRepositoryTests.swift
//  TestDonorClass2Tests
//

import Foundation
import GRDB
import Testing
@testable import TestDonorClass2

struct PrintBatchRepositoryTests {

    @Test func createBatchStampsAllDonationsAsPrinted() async throws {
        let pool = try makeTestPool()
        let repository = PrintBatchRepository(dbPool: pool)

        try await pool.write { db in
            try insertDonation(db, id: 1, status: .queued)
            try insertDonation(db, id: 2, status: .queued)
        }

        let batchId = try await repository.createBatch(donationIds: [1, 2], label: nil)
        #expect(batchId > 0)

        try await pool.read { db in
            let batch = try PrintBatch.fetchOne(db, key: batchId)
            #expect(batch?.receiptCount == 2)
            #expect(batch?.status == .printed)

            let donations = try Row.fetchAll(db, sql: """
                SELECT receipt_status, print_batch_id, printed_at
                FROM donation
                WHERE id IN (1, 2)
                ORDER BY id
                """)
            #expect(donations.count == 2)
            #expect(donations[0]["receipt_status"] as String == ReceiptStatus.printed.rawValue)
            #expect(donations[0]["print_batch_id"] as Int64 == Int64(batchId))
            #expect(donations[0]["printed_at"] as Date? != nil)
            #expect(donations[1]["print_batch_id"] as Int64 == Int64(batchId))
        }
    }

    @Test func revertBatchReturnsDonationsToRequested() async throws {
        let pool = try makeTestPool()
        let repository = PrintBatchRepository(dbPool: pool)

        try await pool.write { db in
            try insertDonation(db, id: 1, status: .queued)
            try insertDonation(db, id: 2, status: .queued)
        }

        let batchId = try await repository.createBatch(donationIds: [1, 2], label: nil)
        try await repository.revertBatch(batchId: batchId)

        try await pool.read { db in
            let batch = try PrintBatch.fetchOne(db, key: batchId)
            #expect(batch?.status == .fullyReverted)

            let donations = try Row.fetchAll(db, sql: """
                SELECT receipt_status, print_batch_id, printed_at
                FROM donation
                WHERE id IN (1, 2)
                ORDER BY id
                """)
            #expect(donations[0]["receipt_status"] as String == ReceiptStatus.requested.rawValue)
            #expect(donations[0]["print_batch_id"] == nil)
            #expect(donations[0]["printed_at"] == nil)
            #expect(donations[1]["receipt_status"] as String == ReceiptStatus.requested.rawValue)
        }
    }

    private func makeTestPool() throws -> DatabasePool {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("print-batch-test-\(UUID().uuidString).sqlite")
        let pool = try DatabasePool(path: url.path)
        try pool.write { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
            try db.create(table: PrintBatch.databaseTableName) { t in
                t.autoIncrementedPrimaryKey(PrintBatch.Columns.id.name)
                t.column(PrintBatch.Columns.printedAt.name, .datetime).notNull()
                t.column(PrintBatch.Columns.receiptCount.name, .integer).notNull()
                t.column(PrintBatch.Columns.label.name, .text)
                t.column(PrintBatch.Columns.status.name, .text).notNull()
            }
            try db.create(table: "donation") { t in
                t.column("id", .integer).primaryKey()
                t.column("receipt_status", .text).notNull()
                t.column("request_printed_receipt", .boolean).notNull().defaults(to: true)
                t.column("print_batch_id", .integer)
                t.column("printed_at", .datetime)
            }
        }
        return pool
    }

    private func insertDonation(_ db: Database, id: Int, status: ReceiptStatus) throws {
        try db.execute(
            sql: """
                INSERT INTO donation (id, receipt_status, request_printed_receipt)
                VALUES (?, ?, 1)
                """,
            arguments: [id, status.rawValue]
        )
    }
}
