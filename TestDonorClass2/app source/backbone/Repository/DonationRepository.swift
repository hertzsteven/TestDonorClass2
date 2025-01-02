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
    
    func getAll() async throws -> [Donation] {
        try await dbPool.read { db in
            try Donation
                .order(Donation.Columns.donationDate.desc)
                .fetchAll(db)
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
}

