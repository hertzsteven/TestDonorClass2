//
//  PledgeRepository.swift
//  TestDonorClass2
//
//  Created by Alex Carmack on 5/20/25.
//

import Foundation
import GRDB

class PledgeRepository: PledgeSpecificRepositoryProtocol {
    typealias Model = Pledge
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

    convenience init() throws {
        do {
            let pool = try DatabaseManager.shared.getDbPool()
            self.init(dbPool: pool)
        } catch {
            print("CRITICAL ERROR: PledgeRepository initialization failed: \(error)")
            throw RepositoryError.fetchFailed("Database connection could not be established: \(error.localizedDescription)")
        }
    }

    private func handleError(_ error: Error, context: String) {
        print("Error in PledgeRepository \(context): \(error.localizedDescription)")
    }

    // MARK: - Basic CRUD Operations

    func getAll() async throws -> [Pledge] {
        do {
            return try await dbPool.read { db in
                try Pledge.order(Pledge.Columns.expectedFulfillmentDate.desc).fetchAll(db)
            }
        } catch {
            handleError(error, context: "getAll")
            throw RepositoryError.readAllFailed(error.localizedDescription)
        }
    }

    func getCount() async throws -> Int {
        do {
            return try await dbPool.read { db in
                try Pledge.fetchCount(db)
            }
        } catch {
            handleError(error, context: "getCount")
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }

    func getOne(_ id: Int) async throws -> Pledge? {
        do {
            return try await dbPool.read { db in
                try Pledge.fetchOne(db, id: id)
            }
        } catch {
            handleError(error, context: "getOne with id: \(id)")
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }

    func insert(_ item: Pledge) async throws {
        var mutableItem = item
        do {
            // Perform validation before inserting
            try mutableItem.validate()
            
            // Ensure createdAt and updatedAt are set
            let now = Date()
            mutableItem.createdAt = now
            mutableItem.updatedAt = now
            
            try await dbPool.write { db in
                try mutableItem.insert(db)
            }
        } catch let validationError as PledgeValidationError {
             handleError(validationError, context: "insert validation")
             throw RepositoryError.insertFailed("Validation failed: \(validationError.localizedDescription)")
        } catch {
            handleError(error, context: "insert")
            throw RepositoryError.insertFailed(error.localizedDescription)
        }
    }

    func update(_ item: Pledge) async throws {
        guard item.id != nil else {
            throw RepositoryError.updateFailed("Cannot update pledge without an ID.")
        }
        var mutableItem = item
        do {
            // Perform validation before updating
            try mutableItem.validate()
            
            // Ensure updatedAt is set
            mutableItem.updatedAt = Date()
            
            try await dbPool.write { db in
                try mutableItem.update(db)
            }
        } catch let validationError as PledgeValidationError {
            handleError(validationError, context: "update validation")
            throw RepositoryError.updateFailed("Validation failed: \(validationError.localizedDescription)")
        } catch {
            handleError(error, context: "update")
            throw RepositoryError.updateFailed(error.localizedDescription)
        }
    }

    func delete(_ item: Pledge) async throws {
        guard let id = item.id else {
            throw RepositoryError.deleteFailed("Cannot delete pledge without an ID.")
        }
        do {
            _ = try await dbPool.write { db in
                try item.delete(db)
            }
        } catch {
            handleError(error, context: "delete pledge with id: \(id)")
            throw RepositoryError.deleteFailed(error.localizedDescription)
        }
    }

    func deleteOne(_ id: Int) async throws {
        do {
            _ = try await dbPool.write { db in
                try Pledge.deleteOne(db, id: id)
            }
        } catch {
            handleError(error, context: "deleteOne pledge with id: \(id)")
            throw RepositoryError.deleteFailed(error.localizedDescription)
        }
    }

    // MARK: - Pledge Specific Repository Protocol Methods

    func getPledgesForDonor(donorId: Int) async throws -> [Pledge] {
        do {
            return try await dbPool.read { db in
                try Pledge
                    .filter(Pledge.Columns.donorId == donorId)
                    .order(Pledge.Columns.expectedFulfillmentDate.desc)
                    .fetchAll(db)
            }
        } catch {
            handleError(error, context: "getPledgesForDonor with donorId: \(donorId)")
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }

    func getPledgesForCampaign(campaignId: Int) async throws -> [Pledge] {
        do {
            return try await dbPool.read { db in
                try Pledge
                    .filter(Pledge.Columns.campaignId == campaignId)
                    .order(Pledge.Columns.expectedFulfillmentDate.desc)
                    .fetchAll(db)
            }
        } catch {
            handleError(error, context: "getPledgesForCampaign with campaignId: \(campaignId)")
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }

    func getPledgesByStatus(status: PledgeStatus) async throws -> [Pledge] {
        do {
            return try await dbPool.read { db in
                try Pledge
                    .filter(Pledge.Columns.status == status.rawValue)
                    .order(Pledge.Columns.expectedFulfillmentDate.desc)
                    .fetchAll(db)
            }
        } catch {
            handleError(error, context: "getPledgesByStatus with status: \(status.rawValue)")
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }
}