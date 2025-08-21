//
//  CampaignRepository.swift
//  TestCampaignClass2
//
//  Created by Steven Hertz on 12/25/24.
//
// MARK: - Repository Protocol
import GRDB
import Foundation

class CampaignRepository: CampaignSpecificRepositoryProtocol {
    typealias Model = Campaign
    
    private var dbPool: DatabasePool {
        get throws {
            try DatabaseManager.shared.getDbPool()
        }
    }
    
    init(dbPool: DatabasePool) {
//        self.dbPool = dbPool
    }
    
    /// Convenience initializer that intentionally crashes if database initialization fails
    /// since the app cannot function without a proper database connection.
    convenience init() throws {
        do {
            let pool = try DatabaseManager.shared.getDbPool()
            self.init(dbPool: pool)
        } catch {
            print("CRITICAL ERROR: Database initialization failed: \(error)")
            print("Application cannot function without database access - terminating")
            fatalError("Database connection could not be established: \(error.localizedDescription)")
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
    func getOne(_ id: Int) async throws -> Campaign? {
        do {
            // attemp to read from database asyncronously
            let campaign = try await dbPool.read { db in
                try Campaign.fetchOne(db, id: id)
            }
            return campaign
        } catch {
            handleError(error, context: "Fetching campaign with id: \(id)")
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }
    func getAll() async throws -> [Campaign] {
        do {
            let campaigns = try await dbPool.read { db in
                try Campaign.fetchAll(db)
            }
            return campaigns
        } catch {
            handleError(error, context: "Failed to fetch all campaigns")
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }
    
    func getCount() async throws -> Int {
        do {
            let count = try await dbPool.read { db in
                try Campaign.fetchCount(db)
            }
            return count
        } catch {
            handleError(error, context: "Failed to count all")
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }

    // MARK: - CRUD
    func insert(_ campaign: Campaign) async throws -> Campaign {
        var newCampaign = campaign
        do {
            try await dbPool.write { db in
                try newCampaign.insert(db)
                let id = db.lastInsertedRowID
                newCampaign.id = Int(id)
            }
            return newCampaign
        } catch {
            handleError(error, context: "Inserting campaign: ")
            throw RepositoryError.insertFailed(error.localizedDescription)
        }
    }
    
    func delete(_ campaign: Campaign) async throws  {
        do {
            try await dbPool.write { db in
                try campaign.delete(db)
            }
        } catch {
            handleError(error, context: "Deleting campaign: ")
            throw RepositoryError.deleteFailed(error.localizedDescription)
        }
    }
    
    func update(_ campaign: Campaign) async throws  {
        do {
            try await dbPool.write { db in
                try campaign.update(db)
            }
        } catch {
            handleError(error, context: "Updating campaign:")
            throw RepositoryError.updateFailed(error.localizedDescription)
        }
    }
    
    func deleteOne(_ id: Int) async throws  {
        do {
            try await dbPool.write { db in
                try Campaign.deleteOne(db, id: id)
            }
        } catch {
            handleError(error, context: "Deleting campaign with id: \(id)")
            throw RepositoryError.deleteFailed(error.localizedDescription)
        }
    }
    // MARK: - Search
    func findByName(_ searchText: String) async throws -> [Campaign] {
        do {
            let campaigns = try await dbPool.read { db in
                try Campaign.filter(Column("name").like("%\(searchText)%") )
                .order(Column("name"))
                .fetchAll(db)
            }
            return campaigns
        } catch {
            handleError(error, context: "Failed to fetch all campaigns")
            throw error
        }
    }

}