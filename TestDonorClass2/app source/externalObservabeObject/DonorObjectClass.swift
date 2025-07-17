//
//  DonorObjectClass.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 12/24/24.
//

import Foundation
import GRDB

class DonorObjectClass: ObservableObject {
    @Published var donors: [Donor] = []
    @Published var errorMessage: String?
    @Published var loadingState: LoadingState = .loaded
    @Published var lastUpdatedDonor: Donor? = nil  // Add this property
    
    private let repository: any DonorSpecificRepositoryProtocol
       
    // --- CHANGE 1: Designated Initializer ---
    // Requires the repository protocol, doesn't throw
    init(repository: any DonorSpecificRepositoryProtocol) {
        self.repository = repository
    }
    
    // --- CHANGE 2: Convenience Initializer ---
    // Takes no arguments, throws because creating the default repository can throw
    convenience init() throws {
        do {
            // Try to create the default repository instance
            let defaultRepository = try DonorRepository()
            // Call the designated initializer
            self.init(repository: defaultRepository)
        } catch {
            print("Failed to initialize DonorObjectClass: Could not create repository. \(error)")
            // Re-throw the error so the caller knows initialization failed
            throw error // You could wrap this in a custom error if needed
        }
    }
    
}
    //  MARK: -  Retreive Donors
extension DonorObjectClass {
    func getDonor(_ id: Int) async throws -> Donor? {
        let donor = try await repository.getOne(id)
        return donor
    }
    
    
        // MARK: - Search Operations
    func searchDonors(_ searchText: String) async throws {
        if searchText.isEmpty {
            await MainActor.run {
                self.donors = []
            }
            return
        }
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 {
            return
        }
        
        let results = try await repository.findByName(searchText)
        await MainActor.run {
            self.donors = results
        }
    }
    
        // MARK: - Search Operations
    func searchDonorsWithReturn(_ searchText: String) async throws -> [Donor] {
        if searchText.isEmpty {
            return []
        }
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 {
            return []
        }
        
        let donors = try await repository.findByName(searchText)
        
        return donors
        
    }
    
        // Add method for searching by ID
    @MainActor
    func searchDonorById(_ id: Int) async {
        updateLoadingState(.loading)
        do {
            if let donor = try await repository.getDonorById(id) {
                self.donors = [donor]
                self.loadingState = .loaded
            } else {
                self.donors = []
                self.loadingState = .loaded
            }
        } catch {
            self.loadingState = .error(error.localizedDescription)
        }
    }

    @MainActor
    func searchDonorByIdWithReturn(_ id: Int) async throws -> Donor? {
        updateLoadingState(.loading)
        var donor: Donor? = nil
        do {
            if let theDonor = try await repository.getDonorById(id) {
                self.loadingState = .loaded
                donor = theDonor
                return donor
            } else {
                throw NSError(domain: "Donor not found", code: 404, userInfo: nil) as Error
            }
        } catch {
            self.loadingState = .error(error.localizedDescription)
        }
        return donor
    }
}


    //  MARK: -  Loading and clearing
extension DonorObjectClass {
    
    func loadDonors() async {
        print("Starting to load donors")
        
        await MainActor.run { loadingState = .loading }
        
        do {
            let fetchedDonors = try await repository.getAll()
                //                let fetchedDonors =    [Donor]()
            print("Fetched donors count: \(fetchedDonors.count)")
            await MainActor.run {
                self.donors = fetchedDonors
                self.loadingState = .loaded
                print("Updated donors array count: \(self.donors.count)")
            }
        } catch {
            print("Error loading donors: \(error.localizedDescription)")
            await MainActor.run {
                self.loadingState = .error(error.localizedDescription)
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func clearDonors() async  {
        print("Starting to clear donors")
        await MainActor.run { loadingState = .loading }
        let fetchedDonors = [Donor]()
        await MainActor.run {
            self.donors = fetchedDonors
            self.loadingState = .loaded
            print("Cleared donors array count: \(self.donors.count)")
        }
    }
}


    // MARK: - CRUD Operations
extension DonorObjectClass {
    
    func addDonor(_ donor: Donor) async throws -> Donor {
        dump(donor)
        let savedDonor = try await repository.insert(donor)
        return savedDonor
    }
    
    func updateDonor(_ donor: Donor) async throws {
        try await repository.update(donor)
    }
    
    func deleteDonor(_ donor: Donor) async throws {
        try await repository.delete(donor)
        await MainActor.run {
            donors.removeAll { $0.id == donor.id }
        }
    }
}


    //  MARK: -  Helper Functions
extension DonorObjectClass {
    @MainActor
    func refreshDonor(_ donor: Donor) {
        self.lastUpdatedDonor = donor
    }
    
    
    func getCount() async throws -> Int {
        let count = try await repository.getCount()
        return count
    }
    
    
    @MainActor
    private func updateLoadingState(_ loadingState: LoadingState) {
        self.loadingState = loadingState
    }
    
        // MARK: - Error Handling
    @MainActor
    func clearError() {
        errorMessage = nil
    }
}