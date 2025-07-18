import Foundation
import GRDB

class DonorObjectClass: ObservableObject {
    @Published var donors: [Donor] = []
    @Published var errorMessage: String?
    @Published var loadingState: LoadingState = .loaded
    @Published var lastUpdatedDonor: Donor? = nil  // Add this property
    
    private var repository: any DonorSpecificRepositoryProtocol
       
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
    
    // NEW METHOD: Reconnect repository if connection is closed
    private func reconnectIfNeeded() async throws {
        do {
            // Test if current repository is working
            _ = try await repository.getCount()
        } catch {
            // If it fails, try to create a new repository instance
            print("Repository connection failed, attempting to reconnect...")
            do {
                let newRepository = try DonorRepository()
                self.repository = newRepository
                print("Successfully reconnected repository")
            } catch {
                print("Failed to reconnect repository: \(error)")
                throw error
            }
        }
    }
    
}

    //  MARK: -  Retreive Donors
extension DonorObjectClass {
    func getDonor(_ id: Int) async throws -> Donor? {
        try await reconnectIfNeeded()
        let donor = try await repository.getOne(id)
        return donor
    }
    
    
        // MARK: - Search Operations
    func searchDonors(_ searchText: String) async throws {
        try await reconnectIfNeeded()
        
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedSearchText.isEmpty {
            await MainActor.run {
                self.donors = []
            }
            return
        }
        if trimmedSearchText.count < 3 {
            return
        }
        
        let results = try await repository.findByName(trimmedSearchText)
        await MainActor.run {
            self.donors = results
        }
    }
    
        // MARK: - Search Operations
    func searchDonorsWithReturn(_ searchText: String) async throws -> [Donor] {
        try await reconnectIfNeeded()
        
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedSearchText.isEmpty {
            return []
        }
        if trimmedSearchText.count < 3 {
            return []
        }
        
        let donors = try await repository.findByName(trimmedSearchText)
        
        return donors
        
    }
    
        // Add method for searching by ID
    @MainActor
    func searchDonorById(_ id: Int) async {
        updateLoadingState(.loading)
        do {
            try await reconnectIfNeeded()
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
            try await reconnectIfNeeded()
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
            try await reconnectIfNeeded()
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
        try await reconnectIfNeeded()
        dump(donor)
        let savedDonor = try await repository.insert(donor)
        return savedDonor
    }
    
    func updateDonor(_ donor: Donor) async throws {
        try await reconnectIfNeeded()
        try await repository.update(donor)
    }
    
    func deleteDonor(_ donor: Donor) async throws {
        try await reconnectIfNeeded()
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
        try await reconnectIfNeeded()
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