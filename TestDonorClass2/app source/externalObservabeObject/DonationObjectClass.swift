//
//  DonationObjectClass.swift
//  TestDonorClass2
//
//  Created by Steven Hertz
//

import Foundation
import GRDB

class DonationObjectClass: ObservableObject {
    // MARK: - Published Properties
    @Published var donations: [Donation] = []
    @Published var errorMessage: String?
    @Published var loadingState: LoadingState = .notLoaded
    
    // MARK: - Private Properties
    private let repository: DonationRepository
    
    // MARK: - Initialization
    init(repository: DonationRepository = DonationRepository()) {
        self.repository = repository
    }
    
    // MARK: - Data Loading
    func loadDonations() async {
        print("Starting to load donations")
        guard loadingState == .notLoaded else {
            print("Skipping load - current state: \(loadingState)")
            return
        }
        
        await MainActor.run { loadingState = .loading }
        
        do {
            let fetchedDonations = try await repository.getAll()
            print("Fetched donations count: \(fetchedDonations.count)")
            await MainActor.run {
                self.donations = fetchedDonations
                self.loadingState = .loaded
                print("Updated donations array count: \(self.donations.count)")
            }
        } catch {
            print("Error loading donations: \(error.localizedDescription)")
            await MainActor.run {
                self.loadingState = .error(error.localizedDescription)
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - CRUD Operations
    func addDonation(_ donation: Donation) async throws {
        try await repository.insert(donation)
        let fetchedDonations = try await repository.getAll()
        await MainActor.run {
            self.donations = fetchedDonations
        }
    }
    
    func updateDonation(_ donation: Donation) async throws {
        try await repository.update(donation)
        await MainActor.run {
            if let index = donations.firstIndex(where: { $0.id == donation.id }) {
                donations[index] = donation
            }
        }
    }
    
    func deleteDonation(_ donation: Donation) async throws {
        try await repository.delete(donation)
        await MainActor.run {
            donations.removeAll { $0.id == donation.id }
        }
    }
    
    // MARK: - Specialized Queries
    func loadDonationsForDonor(donorId: Int) async throws {
        let donorDonations = try await repository.getDonationsForDonor(donorId: donorId)
        await MainActor.run {
            self.donations = donorDonations
        }
    }
    
    func loadDonationsForCampaign(campaignId: Int) async throws {
        let campaignDonations = try await repository.getDonationsForCampaign(campaignId: campaignId)
        await MainActor.run {
            self.donations = campaignDonations
        }
    }
    
    // MARK: - Error Handling
    @MainActor
    func clearError() {
        errorMessage = nil
    }
}

