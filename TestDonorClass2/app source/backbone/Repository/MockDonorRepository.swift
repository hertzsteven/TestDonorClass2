import Foundation
import GRDB // Import GRDB if Donor model or other types from it are used, or for DatabasePool type

// MOCK IMPLEMENTATION
class MockDonorRepository: DonorSpecificRepositoryProtocol {
    // MARK: - Protocol Conformance: Associated Type
    typealias Model = Donor

    // MARK: - Properties
    private var mockDonors: [Donor]
    private var nextId: Int // For generating new IDs if needed

    // MARK: - Initializers Conforming to Protocol Requirements (if any)
    // The DonorSpecificRepositoryProtocol inherits from RepositoryProtocol.
    // RepositoryProtocol does not define initializers, so DonorSpecificRepositoryProtocol
    // doesn't enforce any specific initializers unless added directly to it.
    // DonorRepository has `init(dbPool: DatabasePool)` and `init() throws`.
    // For a mock, we can simplify this. If the protocol *required* these, we'd add them.
    // Since the protocol in RepositoryProtocol.swift doesn't *require* initializers,
    // we can make a simpler one for the mock.

    init(initialDonors: [Donor]? = nil) {
        if let initialDonors = initialDonors {
            self.mockDonors = initialDonors
        } else {
            // Generate some default mock donors if none are provided
            self.mockDonors = MockDonorGenerator.generateMockDonors()
        }
        self.nextId = (self.mockDonors.compactMap { $0.id }.max() ?? 0) + 1
        print("MockDonorRepository initialized with \(self.mockDonors.count) donors.")
    }
    
    // MARK: - Helper to reset/repopulate data
    func repopulate(donors: [Donor]) {
        self.mockDonors = donors
        self.nextId = (self.mockDonors.compactMap { $0.id }.max() ?? 0) + 1
        print("MockDonorRepository repopulated with \(self.mockDonors.count) donors.")
    }

    // MARK: - DonorSpecificRepositoryProtocol Methods

    // From RepositoryProtocol
    func insert(_ donor: Donor) async throws {
        var newDonor = donor
        if newDonor.id == nil {
            newDonor.id = nextId
            nextId += 1
        }
        
        if mockDonors.contains(where: { $0.id == newDonor.id }) {
            print("MockDonorRepository: Insert failed - Donor with ID \(newDonor.id ?? -1) already exists.")
            throw RepositoryError.insertFailed("Donor with ID \(newDonor.id ?? -1) already exists.")
        }
        mockDonors.append(newDonor)
        print("MockDonorRepository: Inserted donor \(newDonor.fullName) with ID \(newDonor.id ?? -1). Total donors: \(mockDonors.count)")
    }

    func getAll() async throws -> [Donor] {
        print("MockDonorRepository: getAll called. Returning \(mockDonors.count) donors.")
        return mockDonors
    }

    func getCount() async throws -> Int {
        print("MockDonorRepository: getCount called. Count: \(mockDonors.count).")
        return mockDonors.count
    }

    func getOne(_ id: Int) async throws -> Donor? {
        print("MockDonorRepository: getOne called for ID \(id).")
        let donor = mockDonors.first { $0.id == id }
        if donor == nil {
            print("MockDonorRepository: Donor with ID \(id) not found.")
        }
        return donor
    }

    func update(_ donor: Donor) async throws {
        guard let id = donor.id else {
            print("MockDonorRepository: Update failed - Donor ID is nil.")
            throw RepositoryError.updateFailed("Donor ID is nil for update.")
        }
        if let index = mockDonors.firstIndex(where: { $0.id == id }) {
            mockDonors[index] = donor
            print("MockDonorRepository: Updated donor with ID \(id).")
        } else {
            print("MockDonorRepository: Update failed - Donor with ID \(id) not found.")
            throw RepositoryError.updateFailed("Donor with ID \(id) not found for update.")
        }
    }

    func delete(_ donor: Donor) async throws {
        guard let id = donor.id else {
            print("MockDonorRepository: Delete failed - Donor ID is nil.")
            throw RepositoryError.deleteFailed("Donor ID is nil for delete.")
        }
        if let index = mockDonors.firstIndex(where: { $0.id == id }) {
            mockDonors.remove(at: index)
            print("MockDonorRepository: Deleted donor with ID \(id).")
        } else {
            print("MockDonorRepository: Delete failed - Donor with ID \(id) not found.")
            throw RepositoryError.deleteFailed("Donor with ID \(id) not found for delete.")
        }
    }

    func deleteOne(_ id: Int) async throws {
        if let index = mockDonors.firstIndex(where: { $0.id == id }) {
            mockDonors.remove(at: index)
            print("MockDonorRepository: Deleted donor via deleteOne with ID \(id).")
        } else {
            print("MockDonorRepository: deleteOne failed - Donor with ID \(id) not found.")
            throw RepositoryError.deleteFailed("Donor with ID \(id) not found for deleteOne.")
        }
    }

    // From DonorSpecificRepositoryProtocol
    func findByName(_ searchText: String) async throws -> [Donor] {
        print("MockDonorRepository: findByName called with searchText '\(searchText)'.")
        if searchText.isEmpty {
            return mockDonors
        }
        let lowercasedSearchText = searchText.lowercased()
        let filtered = mockDonors.filter {
            ($0.firstName?.lowercased().contains(lowercasedSearchText) ?? false) ||
            ($0.lastName?.lowercased().contains(lowercasedSearchText) ?? false) ||
            ($0.company?.lowercased().contains(lowercasedSearchText) ?? false)
        }
        print("MockDonorRepository: Found \(filtered.count) donors for search term '\(searchText)'.")
        return filtered
    }

    func getDonorById(_ id: Int) async throws -> Donor? {
        // This is essentially the same as getOne for this specific protocol.
        // If it had different logic, we'd implement it.
        print("MockDonorRepository: getDonorById called for ID \(id).")
        return try await getOne(id)
    }
}

// Make sure MockDonorGenerator.swift is created and accessible for this to compile.
// It should define MockDonorGenerator.generateDonors(numberOfRecords: Int) -> [Donor]
// and the Donor model.
