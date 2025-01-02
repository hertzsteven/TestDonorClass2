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
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool = DatabaseManager.shared.getDbPool()) {
        self.dbPool = dbPool
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

        // MARK: - CRUD
    func insert(_ campaign: Campaign) async throws  {
        do {
            try await dbPool.write { db in
                try campaign.insert(db) }
        } catch {
            handleError(error, context: "Inserting campaign: ")
            throw RepositoryError.insertFailed(error.localizedDescription)        }
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
                try Campaign.filter(Column("first_name").like("%\(searchText)%") ||
                                 Column("last_name").like("%\(searchText)%"))
                .order(Column("last_name"), Column("first_name"))
                .fetchAll(db)
            }
            return campaigns
        } catch {
            handleError(error, context: "Failed to fetch all campaigns")
            throw error
        }
    }

}
