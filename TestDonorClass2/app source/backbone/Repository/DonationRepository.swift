//
//  DonationRepository.swift
//  TestDonorClass2
//
//  Created by Steven Hertz
//

import Foundation
import GRDB

class DonationRepository: DonationSpecificRepositoryProtocol {

    
    typealias Model = Donation
    private var dbPool: DatabasePool {
        get throws {
            try DatabaseManager.shared.getDbPool()
        }
    }
    
    //        init(dbPool: DatabasePool = DatabaseManager.shared.getDbPool()) {
    //                self.dbPool = dbPool
    //            }
    
    // 1. Designated Initializer (no default value, doesn't throw)
    // This is the main initializer. It requires a valid pool.
    init(dbPool: DatabasePool) {
//        self.dbPool = dbPool
    }
    
    // 2. Convenience Initializer (throws)
    // This initializer provides the convenience of not passing the pool,
    // but it might fail (throw) if getting the shared pool fails.
    convenience init() throws {
        do {
            // Try to get the shared database pool
            let pool = try DatabaseManager.shared.getDbPool()
            // Call the designated initializer with the obtained pool
            self.init(dbPool: pool)
        } catch {
            // If getting the pool failed, rethrow the error
            print("Error initializing \(String(describing: Self.self)): Could not get database pool. \(error)")
            throw error // Or throw a more specific RepositoryError if desired
        }
    }
    // Example error handling function
    private func handleError(_ error: Error, context: String) {
            // Log the error with context
        print("Error in \(context): \(error.localizedDescription)")
            // You can add more sophisticated error handling here, such as:
            // - Sending error reports to a monitoring service
            // - Displaying user-friendly messages
            // - Retrying the operation if applicable
    }
    
    func getAll() async throws -> [Donation] {
        try await dbPool.read { db in
            try Donation
                .order(Donation.Columns.donationDate.desc)
                .fetchAll(db)
        }
    }
    
    func getCount() async throws -> Int {
        do {
            let count = try await dbPool.read { db in
                try Donation.fetchCount(db)
            }
            return count
        } catch {
            handleError(error, context: "Failed to count all")
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }
    
    func getOne(_ id: Int) async throws -> Donation? {
        try await dbPool.read { db in
            try Donation.fetchOne(db, id: id)
        }
    }
    
    func insert(_ item: Donation) async throws -> Donation {
        var newDonation = item
        do {
            try await dbPool.write { db in
                try newDonation.insert(db)
                let id = db.lastInsertedRowID
                newDonation.id = Int(id)
            }
            return newDonation
        } catch {
            handleError(error, context: "Inserting donation")
            throw RepositoryError.insertFailed(error.localizedDescription)
        }
    }
    
    func update(_ item: Donation) async throws {
        guard item.id != nil else { fatalError("can't update an item without an id") }
        try await dbPool.write { db in
            try item.update(db)
        }
    }
    
    func delete(_ item: Donation) async throws {
        guard let id = item.id else { fatalError("can't delete an item without an id")  }
        try await dbPool.write { db in
            try item.delete(db)
        }
    }
    
    func deleteOne(_ id: Int) async throws  {
        do {
            try await dbPool.write { db in
                try Donation.deleteOne(db, id: id)
            }
        } catch {
            handleError(error, context: "Deleting donation with id: \(id)")
            throw RepositoryError.deleteFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Custom Queries
    func getDonationsForDonor(donorId: Int) async throws -> [Donation] {
        try await dbPool.read { db in
            try Donation
                .filter(Donation.Columns.donorId == donorId)
                .order(Donation.Columns.donationDate.desc)
                .fetchAll(db)
        }
    }
    
    func getDonationsForCampaign(campaignId: Int) async throws -> [Donation] {
        try await dbPool.read { db in
            try Donation
                .filter(Donation.Columns.campaignId == campaignId)
                .order(Donation.Columns.donationDate.desc)
                .fetchAll(db)
        }
    }
    
    func getTotalDonationsAmount(forDonorId donorId: Int) async throws -> Double {
        try await dbPool.read { db in
            try Donation
                .filter(Donation.Columns.donorId == donorId)
                .select(sum(Donation.Columns.amount))
                .asRequest(of: Double.self)
                .fetchOne(db) ?? 0.0
        }
    }
    
    func getDonationsForIncentive(incentiveId: Int) async throws -> [Donation] {
        try await dbPool.read { db in
            try Donation
                .filter(Donation.Columns.donationIncentiveId == incentiveId)
                .order(Donation.Columns.donationDate.desc)
                .fetchAll(db)
        }
    }
}
extension DonationRepository {
    func getReceiptRequests(status: ReceiptStatus) async throws -> [Donation] {
        try await dbPool.read { db in
            // Create year 2000 date for filtering
            // Create year 2000 date for filtering - using Calendar for safe date creation
            let calendar = Calendar(identifier: .gregorian)
            let cutoffDate = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date.distantPast

            return try Donation
                .filter(
                    // If status is .notRequested, ignore requestPrintedReceipt
                    // For all other statuses (requested, queued, printed, failed), check requestPrintedReceipt
                    status == .notRequested ?
                        (Donation.Columns.receiptStatus == status.rawValue && Donation.Columns.donationDate > cutoffDate) :
                        (Donation.Columns.requestPrintedReceipt == true && Donation.Columns.receiptStatus == status.rawValue)
                )

//                .filter(Donation.Columns.requestPrintedReceipt == true && Donation.Columns.receiptStatus == status.rawValue)
                .order(Donation.Columns.donationDate.desc)
                .fetchAll(db)
        }
    }
    
    func countReceiptsByStatus(_ status: ReceiptStatus) async throws -> Int {
        try await dbPool.read { db in
            // Create year 2000 date for filtering - using Calendar for safe date creation
            let calendar = Calendar(identifier: .gregorian)
            let cutoffDate = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date.distantPast

            return try Donation
                .filter(
                    // If status is .notRequested, ignore requestPrintedReceipt
                    // For all other statuses (requested, queued, printed, failed), check requestPrintedReceipt
                    status == .notRequested ?
                        (Donation.Columns.receiptStatus == status.rawValue && Donation.Columns.donationDate > cutoffDate) :
                        (Donation.Columns.requestPrintedReceipt == true && Donation.Columns.receiptStatus == status.rawValue)
                )
                .fetchCount(db)
        }
    }
    
    /// Updates a donation's receipt status. When transitioning to `.queued`
    /// and the donation has no receipt number yet, a fresh number is assigned
    /// in the **same write transaction** as the status update. Because GRDB
    /// serializes writes, computing the next number and persisting it in one
    /// transaction prevents two concurrent queues from reading the same
    /// counter and producing duplicate receipt numbers.
    func updateReceiptStatus(donationId: Int, status: ReceiptStatus) async throws {
        try await dbPool.write { db in
            guard status == .queued else {
                if status == .requested {
                    try db.execute(sql: """
                        UPDATE donation
                        SET receipt_status = ?, print_batch_id = NULL, printed_at = NULL
                        WHERE id = ?
                        """, arguments: [status.rawValue, donationId])
                } else {
                    try db.execute(sql: """
                        UPDATE donation
                        SET receipt_status = ?
                        WHERE id = ?
                        """, arguments: [status.rawValue, donationId])
                }
                return
            }

            let existingNumber = try String.fetchOne(db, sql: """
                SELECT receipt_number FROM donation
                WHERE id = ? AND receipt_number IS NOT NULL AND receipt_number != ''
                """, arguments: [donationId])

            if existingNumber != nil {
                try db.execute(sql: """
                    UPDATE donation
                    SET receipt_status = ?
                    WHERE id = ?
                    """, arguments: [status.rawValue, donationId])
                return
            }

            let receiptNumber = try Self.computeNextReceiptNumber(db: db)
            try db.execute(sql: """
                UPDATE donation
                SET receipt_status = ?, receipt_number = ?
                WHERE id = ?
                """, arguments: [status.rawValue, receiptNumber, donationId])
        }
    }
    
//    func updateReceiptStatus(donationId: Int, status: ReceiptStatus) async throws {
//        if status == .queued {
//            let receiptNumber = try await generateReceiptNumber()
//            try await dbPool.write { db in
//                try db.execute(sql: """
//                    UPDATE donation
//                    SET receipt_status = ?, receipt_number = ?
//                    WHERE id = ?
//                    """, arguments: [status.rawValue, receiptNumber, donationId])
//            }
//        } else {
//            try await dbPool.write { db in
//                try db.execute(sql: """
//                    UPDATE donation
//                    SET receipt_status = ?
//                    WHERE id = ?
//                    """, arguments: [status.rawValue, donationId])
//            }
//        }
//    }
    
//    func updateReceiptStatus(donationId: Int, status: ReceiptStatus) async throws {
//        try await dbPool.write { db in
//            try db.execute(sql: """
//                UPDATE donation
//                SET receipt_status = ?
//                WHERE id = ?
//                """, arguments: [status.rawValue, donationId])
//        }
//    }
    
    func countPendingReceipts() async throws -> Int {
        try await dbPool.read { db in
            try Donation
                .filter(Donation.Columns.requestPrintedReceipt == true &&
                       (Donation.Columns.receiptStatus == ReceiptStatus.requested.rawValue ||
                        Donation.Columns.receiptStatus == ReceiptStatus.queued.rawValue))
                .fetchCount(db)
        }
    }
    func getDonorForDonation(donorId: Int) async throws -> Donor? {
        try await dbPool.read { db in
            try Donor.fetchOne(db, id: donorId)
        }
    }
    
    func getCampaignForDonation(campaignId: Int) async throws -> Campaign? {
        try await dbPool.read { db in
            try Campaign.fetchOne(db, id: campaignId)
        }
    }
    
    /// Read-only preview of the next receipt number that *would* be assigned
    /// for the current year. Not used for actual assignment — assignment goes
    /// through `updateReceiptStatus(_:status: .queued)`, which computes and
    /// stores the number atomically inside one write transaction.
    func generateReceiptNumber() async throws -> String {
        try await dbPool.read { db in
            try Self.computeNextReceiptNumber(db: db)
        }
    }

    /// Computes the next receipt number for the current Gregorian year using
    /// the supplied database handle. Must be invoked inside the same
    /// transaction as the subsequent UPDATE so that the count and the write
    /// are serialized as a single unit.
    ///
    /// Counts donations whose `receipt_number` has already been issued
    /// (non-NULL, non-empty) — not just `.printed` ones — so that queued
    /// receipts also reserve their slot in the sequence.
    private static func computeNextReceiptNumber(db: Database) throws -> String {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: Date())
        guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let startOfNextYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            throw DatabaseError.databaseSetupFailed("Could not compute year range for receipt numbering")
        }

        let issuedCount = try Int.fetchOne(db, sql: """
            SELECT COUNT(*) FROM donation
            WHERE receipt_number IS NOT NULL
              AND receipt_number != ''
              AND donation_date >= ?
              AND donation_date <  ?
            """, arguments: [startOfYear, startOfNextYear]) ?? 0

        return String(format: "R-%d-%06d", year, issuedCount + 1)
    }
    
    /// Updates all donations with status .notRequested and amount >= minAmount to .requested
    /// Also sets requestPrintedReceipt = true so they appear in the Requested queue
    /// - Parameter minAmount: Minimum donation amount threshold
    /// - Returns: The count of updated donations
    func bulkUpdateToRequested(minAmount: Double) async throws -> Int {
        // Create year 2000 date for filtering (same logic as getReceiptRequests)
        let calendar = Calendar(identifier: .gregorian)
        let cutoffDate = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date.distantPast
        
        return try await dbPool.write { db in
            let updateCount = try Donation
                .filter(
                    Donation.Columns.receiptStatus == ReceiptStatus.notRequested.rawValue &&
                    Donation.Columns.amount >= minAmount &&
                    Donation.Columns.donationDate > cutoffDate
                )
                .fetchCount(db)
            
            try db.execute(sql: """
                UPDATE donation
                SET receipt_status = ?, request_printed_receipt = 1
                WHERE receipt_status = ?
                AND amount >= ?
                AND donation_date > ?
                """, arguments: [
                    ReceiptStatus.requested.rawValue,
                    ReceiptStatus.notRequested.rawValue,
                    minAmount,
                    cutoffDate
                ])
            
            return updateCount
        }
    }
}