//
//  MockDonorRepository.swift
//  TestDonorClass2
//
//  Created by AI Assistant on 1/5/25.
//

import Foundation
import GRDB

class MockDonorRepository: DonorSpecificRepositoryProtocol {
    private var mockDonors: [Donor] = []
    
    init() {
        // Generate some mock donors
        self.mockDonors = MockDonorGenerator.generateMockDonors()
    }
    
    init(donors: [Donor]) {
        self.mockDonors = donors
    }
    
    // MARK: - RepositoryProtocol Methods
    
    func getAll() async throws -> [Donor] {
        return mockDonors
    }
    
    func getOne(_ id: Int) async throws -> Donor? {
        return mockDonors.first { $0.id == id }
    }
    
    func insert(_ donor: Donor) async throws -> Donor {
        var newDonor = donor
        // Assign a new ID if needed
        if newDonor.id == nil {
            let maxId = mockDonors.map { $0.id ?? 0 }.max() ?? 0
            newDonor.id = maxId + 1
        }
        mockDonors.append(newDonor)
        return newDonor
    }
    
    func update(_ donor: Donor) async throws {
        guard let index = mockDonors.firstIndex(where: { $0.id == donor.id }) else {
            throw RepositoryError.updateFailed("Donor with id \(donor.id ?? -1) not found")
        }
        mockDonors[index] = donor
    }
    
    func delete(_ donor: Donor) async throws {
        mockDonors.removeAll { $0.id == donor.id }
    }
    
    func deleteOne(_ id: Int) async throws {
        mockDonors.removeAll { $0.id == id }
    }
    
    func getCount() async throws -> Int {
        return mockDonors.count
    }
    
    // MARK: - DonorSpecificRepositoryProtocol Methods
    
    func findByName(_ searchText: String) async throws -> [Donor] {
        return mockDonors.filter { donor in
            let fullName = donor.fullName.lowercased()
            let search = searchText.lowercased()
            return fullName.contains(search) || 
                   (donor.company?.lowercased().contains(search) ?? false)
        }
    }
    
    func getDonorById(_ id: Int) async throws -> Donor? {
        return mockDonors.first { $0.id == id }
    }
}