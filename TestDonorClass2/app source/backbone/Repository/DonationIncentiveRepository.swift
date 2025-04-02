//
// DonationIncentiveRepository.swift
// TestDonorClass2
//

import GRDB
import Foundation

class DonationIncentiveRepository: DonationIncentiveSpecificRepositoryProtocol {
    typealias Model = DonationIncentive
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
    
    // MARK: - Error Handling
    private func handleError(_ error: Error, context: String) {
        print("Error in \(context): \(error.localizedDescription)")
    }
    
    // MARK: - Read Operations
    func getOne(_ id: Int) async throws -> DonationIncentive? {
        do {
            let incentive = try await dbPool.read { db in
                try DonationIncentive.fetchOne(db, id: id)
            }
            return incentive
        } catch {
            handleError(error, context: "Fetching incentive with id: \(id)")
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }
    
    func getAll() async throws -> [DonationIncentive] {
        do {
            let incentives = try await dbPool.read { db in
                try DonationIncentive.fetchAll(db)
            }
            return incentives
        } catch {
            handleError(error, context: "Failed to fetch all incentives")
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }
    
    func getCount() async throws -> Int {
        do {
            let count = try await dbPool.read { db in
                try DonationIncentive.fetchCount(db)
            }
            return count
        } catch {
            handleError(error, context: "Failed to count all")
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }
    
    // MARK: - CRUD Operations
    func insert(_ incentive: DonationIncentive) async throws {
        do {
            try await dbPool.write { db in
                try incentive.insert(db)
            }
        } catch {
            handleError(error, context: "Inserting incentive")
            throw RepositoryError.insertFailed(error.localizedDescription)
        }
    }
    
    func delete(_ incentive: DonationIncentive) async throws {
        do {
            try await dbPool.write { db in
                // Safely unwrap the ID before checking
                guard let id = incentive.id else {
                    throw RepositoryError.deleteFailed("Incentive has no ID")
                }
                
                // Check if incentive is in use
                //                        if try self.isIncentiveInUse(id, db: db) {
                //                            throw IncentiveError.cannotDeleteInUse(incentive.name)
                //                        }
                try incentive.delete(db)
            }
        } catch let error as IncentiveError {
            handleError(error, context: "Checking incentive usage")
            throw error
        } catch {
            handleError(error, context: "Deleting incentive")
            throw RepositoryError.deleteFailed(error.localizedDescription)
        }
    }
    
    func update(_ incentive: DonationIncentive) async throws {
        do {
            try await dbPool.write { db in
                try incentive.update(db)
            }
        } catch {
            handleError(error, context: "Updating incentive")
            throw RepositoryError.updateFailed(error.localizedDescription)
        }
    }
    
    func deleteOne(_ id: Int) async throws {
        do {
            try await dbPool.write { db in
                // Fetch the incentive to get its name for the error message
                guard let incentive = try DonationIncentive.fetchOne(db, id: id) else {
                    throw RepositoryError.deleteFailed("Incentive not found")
                }
                
                //                        // Check if incentive is in use
                //                        if try self.isIncentiveInUse(id) {
                //                            throw IncentiveError.cannotDeleteInUse(incentive.name)
                //                        }
                
                try DonationIncentive.deleteOne(db, id: id)
            }
        } catch let error as IncentiveError {
            handleError(error, context: "Checking incentive usage")
            throw error
        } catch {
            handleError(error, context: "Deleting incentive with id: \(id)")
            throw RepositoryError.deleteFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Search Operations
    func findByName(_ searchText: String) async throws -> [DonationIncentive] {
        do {
            let incentives = try await dbPool.read { db in
                try DonationIncentive
                    .filter(Column("name").like("%\(searchText)%"))
                    .order(Column("name"))
                    .fetchAll(db)
            }
            return incentives
        } catch {
            handleError(error, context: "Search incentives by name")
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }
    
    // Add this new helper method
    func isIncentiveInUse(_ id: Int) async throws -> Bool {
        do {
            let countdb = try await dbPool.read { db in
                try Donation
                    .filter(Column("donation_incentive_id") == id)
                    .fetchCount(db)
            }
            return countdb > 0
        } catch {
            handleError(error, context: "Checking Donations with id: \(id)")
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }
}

enum IncentiveError: LocalizedError {
    case cannotDeleteInUse(String)
    
    var errorDescription: String? {
        switch self {
        case .cannotDeleteInUse(let name):
            return "Cannot delete incentive '\(name)' because it is being used by one or more donations"
        }
    }
}
