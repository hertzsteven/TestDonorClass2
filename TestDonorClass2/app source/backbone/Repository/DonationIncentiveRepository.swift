//
// DonationIncentiveRepository.swift
// TestDonorClass2
//

import GRDB
import Foundation

class DonationIncentiveRepository: DonationIncentiveSpecificRepositoryProtocol {
    typealias Model = DonationIncentive
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool = DatabaseManager.shared.getDbPool()) {
        self.dbPool = dbPool
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
                try incentive.delete(db)
            }
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
                try DonationIncentive.deleteOne(db, id: id)
            }
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
}

