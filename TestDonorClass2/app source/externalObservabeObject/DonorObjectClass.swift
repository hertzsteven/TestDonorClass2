    //
    //  DonorObjectClass.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz on 12/24/24.
    //

    import Foundation
    import GRDB

    @MainActor
    class DonorObjectClass: ObservableObject {
        // MARK: - Published Properties
        @Published var donors: [Donor] = []
        @Published var errorMessage: String?
        @Published var loadingState: LoadingState = .notLoaded
        
        // MARK: - Private Properties
        private let repository: DonorRepository
        
        // MARK: - Initialization
        init(repository: DonorRepository = DonorRepository()) {
            self.repository = repository
        }
        
        // MARK: - Data Loading
        func loadDonors() async {
            print("Starting to load donors")
            guard loadingState == .notLoaded else { 
                print("Skipping load - current state: \(loadingState)")
                return 
            }
            
            loadingState = .loading
            
            do {
                let fetchedDonors = try await repository.getAll()
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
        
        // MARK: - CRUD Operations
        func addDonor(_ donor: Donor) async throws {
            try await repository.insert(donor)
            let fetchedDonors = try await repository.getAll()
            await MainActor.run {
                self.donors = fetchedDonors
            }
        }
        
        func updateDonor(_ donor: Donor) async throws {
            try await repository.update(donor)
            if let index = donors.firstIndex(where: { $0.id == donor.id }) {
                donors[index] = donor
            }
        }
        
        func deleteDonor(_ donor: Donor) async throws {
            try await repository.delete(donor)
            donors.removeAll { $0.id == donor.id }
        }
        
        // MARK: - Search Operations
        func searchDonors(_ searchText: String) async throws {
            if searchText.isEmpty {
                await loadDonors()
                return
            }
            
            let results = try await repository.findByName(searchText)
            await MainActor.run {
                self.donors = results
            }
        }
        
    //    // MARK: - Analytics
    //    func getTotalDonations(for donor: Donor) async throws -> Double {
    //        try await repository.getTotalDonationsAmount(forDonorId: donor.id)
    //    }
        
        // MARK: - Error Handling
        func clearError() {
            errorMessage = nil
        }
    }
