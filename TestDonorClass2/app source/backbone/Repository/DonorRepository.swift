//
//  DonorRepository.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 12/25/24.
//
// MARK: - Repository Protocol
import GRDB
import Foundation

class DonorRepository: DonorSpecificRepositoryProtocol {
    typealias Model = Donor
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

        // MARK: - Read Operations
    func getOne(_ id: Int) async throws -> Donor? {
        do {
                // attemp to read from database asyncronously
            let donor = try await dbPool.read { db in
                try Donor.fetchOne(db, id: id)
            }
            return donor
        } catch {
            handleError(error, context: "Fetching donor with id: \(id)")
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }
    func getAll() async throws -> [Donor] {
        do {
            let donors = try await dbPool.read { db in
                try Donor.fetchAll(db)
            }
            return donors
        } catch {
            handleError(error, context: "Failed to fetch all donors")
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }
    func getCount() async throws -> Int {
        do {
            let count = try await dbPool.read { db in
                try Donor.fetchCount(db)
            }
            return count
        } catch {
            handleError(error, context: "Failed to count all")
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }

        // MARK: - CRUD
    /// Inserts a new donor into the database and returns the saved instance with its ID.
    func insert(_ donor: Donor) async throws -> Donor {
        var newDonor = donor
        do {
            try await dbPool.write { db in
                try newDonor.insert(db)
                let id = db.lastInsertedRowID
                newDonor.id = Int(id)
            }            
            return newDonor
        } catch {
            // Re-throw the error as our custom RepositoryError type.
            throw RepositoryError.insertFailed(error.localizedDescription)
        }
    }
    
    /// Updates an existing donor in the database.
    func update(_ donor: Donor) async throws  {
        do {
            try await dbPool.write { db in
                try donor.update(db)
            }
        } catch {
            handleError(error, context: "Updating donor: \(donor.firstName) \(donor.lastName)")
            throw RepositoryError.updateFailed(error.localizedDescription)
        }
    }
    
    func delete(_ donor: Donor) async throws  {
        do {
            try await dbPool.write { db in
                try donor.delete(db)
            }
        } catch {
            handleError(error, context: "Deleting donor: \(donor.firstName) \(donor.lastName)")
            throw RepositoryError.deleteFailed(error.localizedDescription)
        }
    }
    
    func deleteOne(_ id: Int) async throws  {
        do {
            try await dbPool.write { db in
                try Donor.deleteOne(db, id: id)
            }
        } catch {
            handleError(error, context: "Deleting donor with id: \(id)")
            throw RepositoryError.deleteFailed(error.localizedDescription)
        }
    }
        // MARK: - Search
    func findByName(_ searchText: String) async throws -> [Donor] {
        do {
            let donors = try await dbPool.read { db in
                try Donor.filter(Column("first_name").like("%\(searchText)%") ||
                                 Column("last_name").like("%\(searchText)%") ||
                                 Column("company").like("%\(searchText)%"))
                .order(Column("last_name"), Column("first_name"))
                .fetchAll(db)
            }
            return donors
        } catch {
            handleError(error, context: "Failed to fetch all donors")
            throw error
        }
    }
    
    
        // Add implementation for getting donor by ID
        func getDonorById(_ id: Int) async throws -> Donor? {
            try await dbPool.read { db in
                try Donor.filter(Column("id") == id).fetchOne(db)
            }
        }
        
        // Implement findByName (renamed from searchDonors)
    func findByNameX(_ name: String) async throws -> [Donor] {
            try await dbPool.read { db in
                try Donor
                    .filter(Column("firstName").lowercased.like("%\(name.lowercased())%")
                            || Column("lastName").lowercased.like("%\(name.lowercased())%"))
                    .fetchAll(db)
            }
        }

        // MARK: - Activities
        //        func getTotalDonationsAmount(forDonorId id: Int) async throws -> Double {
        //            do {
        //                let amount = try await dbPool.read { db in
        //                    try Donation
        //                        // Notice the filter uses the `id` parameter here:
        //                        .filter(Column("donor_id") == id)
        //                        .select(sum(Column("amount")))
        //                        .fetchOne(db) ?? 0
        //                }
        //                return Double(amount)
        //            } catch {
        //                    // Optional: log or handle error
        //                throw error
        //            }
        //        }
}
