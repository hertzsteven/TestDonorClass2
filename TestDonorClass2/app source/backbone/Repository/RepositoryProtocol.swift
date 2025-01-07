//
//  RepositoryProtocol.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 12/25/24.
//

import GRDB
import Foundation
    /// A generic repository protocol for basic CRUD operations.
    /// This is the minimal set of methods for any entity type.
protocol RepositoryProtocol {
    associatedtype Model
        // Create
    func insert(_ item: Model) async throws
        // Read
    func getAll() async throws -> [Model]
    func getOne(_ id: Int) async throws -> Model?
        // Update
    func update(_ item: Model) async throws
        // Delete
    func delete(_ item: Model) async throws
        //DeleteOne
    func deleteOne(_ id: Int) async throws
}


protocol DonorSpecificRepositoryProtocol: RepositoryProtocol where Model == Donor {
        /// Find donors by a name or partial name match
    func findByName(_ searchText: String) async throws -> [Donor]
        /// A domain-specific method:
        /// e.g. total donation amount for a particular donor.
        //        func getTotalDonationsAmount(forDonorId id: Int) async throws -> Double
        // Add new method for searching by ID
        func getDonorById(_ id: Int) async throws -> Donor?
        
        // Rename existing search method for clarity
//        func findByName(_ name: String) async throws -> [Donor]


}

    protocol DonationSpecificRepositoryProtocol: RepositoryProtocol where Model == Donation {
    //    /// Find donors by a name or partial name match
    //    func findByName(_ searchText: String) async throws -> [Donor]
    //    /// A domain-specific method:
    //    /// e.g. total donation amount for a particular donor.
    //    func getTotalDonationsAmount(forDonorId id: Int) async throws -> Double
        
//        func getMaxId() async throws -> Int?
        
        func getTotalDonationsAmount(forDonorId donorId: Int) async throws -> Double

        func getDonationsForCampaign(campaignId: Int) async throws -> [Donation]

        func getDonationsForDonor(donorId: Int) async throws -> [Donation]

    }
    protocol CampaignSpecificRepositoryProtocol: RepositoryProtocol where Model == Campaign {
//    //    /// Find donors by a name or partial name match
//    //    func findByName(_ searchText: String) async throws -> [Donor]
//    //    /// A domain-specific method:
//    //    /// e.g. total donation amount for a particular donor.
//    //    func getTotalDonationsAmount(forDonorId id: Int) async throws -> Double
    }

protocol DonationIncentiveSpecificRepositoryProtocol: RepositoryProtocol where Model == DonationIncentive {
    // Add any specific methods for DonationIncentive here if needed
    func findByName(_ searchText: String) async throws -> [DonationIncentive]
}

//
