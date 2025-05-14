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
        private let dbPool: DatabasePool
        
        //        init(dbPool: DatabasePool = DatabaseManager.shared.getDbPool()) {
        //                self.dbPool = dbPool
        //            }
        
        // 1. Designated Initializer (no default value, doesn't throw)
        // This is the main initializer. It requires a valid pool.
        init(dbPool: DatabasePool) {
            self.dbPool = dbPool
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
        
        func insert(_ item: Donation) async throws {
            try await dbPool.write { db in
                try item.insert(db)
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
    
    func updateReceiptStatus(donationId: Int, status: ReceiptStatus) async throws {
        try await dbPool.write { db in
            try db.execute(sql: """
                UPDATE donation
                SET receipt_status = ?
                WHERE id = ?
                """, arguments: [status.rawValue, donationId])
        }
    }
    
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
}
