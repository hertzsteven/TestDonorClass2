//
// DonationIncentiveObjectClass.swift
// TestDonorClass2
//

import Foundation
import GRDB

class DonationIncentiveObjectClass: ObservableObject {
    // MARK: - Published Properties
    @Published var incentives: [DonationIncentive] = []
    @Published var errorMessage: String?
    @Published var loadingState: LoadingState = .notLoaded
    
    // MARK: - Private Properties
    private let repository: any DonationIncentiveSpecificRepositoryProtocol
    var allLoadedDonationIncentives: [DonationIncentive] = []
    
    // MARK: - Initialization
    init(repository: DonationIncentiveRepository = DonationIncentiveRepository()) {
        self.repository = repository
    }
    
    // MARK: - Data Loading
    func loadIncentives() async {
        print("Starting to load donation incentives")
        guard loadingState == .notLoaded else {
            print("Skipping load - current state: \(loadingState)")
            return
        }
        
        await MainActor.run { loadingState = .loading }
        
        do {
            allLoadedDonationIncentives = try await repository.getAll()
            print("Fetched incentives count: \(allLoadedDonationIncentives.count)")
            await refreshDonationIncentivesFromLoaded()
            await MainActor.run {
//                self.incentives = fetchedIncentives
                self.loadingState = .loaded
                print("Updated incentives array count: \(self.incentives.count)")
            }
        } catch {
            print("Error loading incentives: \(error.localizedDescription)")
            await MainActor.run {
                self.loadingState = .error(error.localizedDescription)
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Search Operations
    func searchIncentives(_ query: String) async {
        await MainActor.run { loadingState = .loading }
        
        do {
            var filteredIncentivess : [DonationIncentive] = []
            if !query.isEmpty {
                filteredIncentivess = allLoadedDonationIncentives.filter { incentive in
                    incentive.name.localizedCaseInsensitiveContains(query)
                }
            }else {
                filteredIncentivess = allLoadedDonationIncentives
            }
            
            
            await MainActor.run {
                self.incentives = filteredIncentivess
                self.loadingState = .loaded
            }
        } catch {
            await MainActor.run {
                self.loadingState = .error(error.localizedDescription)
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func isInUse(id: Int) async throws -> Bool {
        let inUse = try await repository.isIncentiveInUse(id)
        print("Incentive in use: \(inUse)")
        return inUse
    }
    
    @MainActor
    func setNotLoaded() {
        loadingState = .notLoaded
    }

    
    
    // MARK: - CRUD Operations
    func addIncentive(_ incentive: DonationIncentive) async throws {
        try await repository.insert(incentive)
        allLoadedDonationIncentives = try await repository.getAll()
        await refreshDonationIncentivesFromLoaded()

    }
    
    func updateIncentive(_ incentive: DonationIncentive) async throws {
        try await repository.update(incentive)
        if let index = allLoadedDonationIncentives.firstIndex(where: { $0.id == incentive.id }) {
            allLoadedDonationIncentives[index] = incentive
        }
        await MainActor.run {
            if let index = incentives.firstIndex(where: { $0.id == incentive.id }) {
                incentives[index] = incentive
            }
        }
    }
    
    func deleteIncentive(_ incentive: DonationIncentive) async throws {
        try await repository.delete(incentive)
        allLoadedDonationIncentives.removeAll() { $0.id == incentive.id }
        await MainActor.run {
            incentives.removeAll { $0.id == incentive.id }
        }
    }
    
    // MARK: - Error Handling
    @MainActor
    func clearIncentives() {
        incentives.removeAll()
    }
    
    @MainActor
    func refreshDonationIncentivesFromLoaded() {
        incentives.removeAll()
        incentives = allLoadedDonationIncentives
    }

    @MainActor
    func clearError() {
        errorMessage = nil
    }
    
    func getTotalIncentiveCount() async throws -> Int {
        return try await repository.getCount()
    }

}
