//
//  BatchPledgeViewModel.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 5/19/25.
//

import SwiftUI

@MainActor
class BatchPledgeViewModel: ObservableObject {
    
    enum RowProcessStatus: Equatable {
        case none
        case success
        case failure(message: String)
    }
    
    struct PledgeEntry: Identifiable {
        let id = UUID()
        var donorID: Int?
        var displayInfo: String
        var pledgeOverride: Double
        var prayerNoteSW: Bool
        var prayerNote: String?
        var pledgeStatusOverride: PledgeStatus
        var expectedFulfillmentDate: Date
        var isValidDonor: Bool
        var processStatus: RowProcessStatus
        var hasPledgeOverride: Bool { pledgeOverride > 0.0 }
        
        init(
            donorID: Int? = nil,
            displayInfo: String = "",
            pledgeOverride: Double = 0.0,
            prayerNoteSW: Bool = false,
            prayerNote: String? = nil,
            pledgeStatusOverride: PledgeStatus = .pledged,
            expectedFulfillmentDate: Date,
            isValidDonor: Bool = false,
            processStatus: RowProcessStatus = .none
        ) {
            self.donorID = donorID
            self.displayInfo = displayInfo
            self.pledgeOverride = pledgeOverride
            self.prayerNoteSW = prayerNoteSW
            self.prayerNote = prayerNote
            self.pledgeStatusOverride = pledgeStatusOverride
            self.expectedFulfillmentDate = expectedFulfillmentDate
            self.isValidDonor = isValidDonor
            self.processStatus = processStatus
        }
    }
    
    // MARK: - Private Properties
    // Use protocols and remove default values
    private let repository: any DonorSpecificRepositoryProtocol
    
    
    @Published var globalPledgeAmount: Double = 50.0
    @Published var globalPledgeStatus: PledgeStatus = .pledged
    @Published var globalExpectedFulfillmentDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
    
    @Published var rows: [PledgeEntry] = []
    @Published var focusedRowID: UUID? = nil
    
    private var mockDonors: [Donor] = []
    
    init(repository: any DonorSpecificRepositoryProtocol) {
        self.repository = repository
        setupMockData()
        addRow()
        print("BatchPledgeViewModel Initialized")
    }
    
    private func setupMockData() {
//        mockDonors = [
//            Donor(id: 101, firstName: "Alice", lastName: "Smith", address: "10 Park Ave", city: "Pledgeville", state: "NY", email: "alice@example.com"),
//            Donor(id: 102, firstName: "Bob", lastName: "Johnson", company: "Pledge Corp", address: "20 Main St", city: "Pledgeburg", state: "CA", email: "bob@example.com"),
//            Donor(id: 103, firstName: "Carol", lastName: "Williams", address: "30 Oak Ln", city: "Pledgeton", state: "TX", email: "carol@example.com"),
//            Donor(id: 104, firstName: "David", lastName: "Brown", address: "40 Pine Rd", city: "Pledgeside", state: "FL", email: "dave@example.com")
//        ]
    }
    
    func addRow() {
        let newRow = PledgeEntry(
            pledgeStatusOverride: self.globalPledgeStatus,
            expectedFulfillmentDate: self.globalExpectedFulfillmentDate
        )
        rows.append(newRow)
    }
    
    func clearBatch() {
        rows.removeAll()
        addRow()
        focusedRowID = rows.first?.id
    }
    
    func findDonor(for rowID: UUID) async {
        guard let rowIndex = rows.firstIndex(where: { $0.id == rowID }) else { return }
        
        guard let donorID = rows[rowIndex].donorID else {
            rows[rowIndex].displayInfo = "Please enter a Donor ID"
            rows[rowIndex].isValidDonor = false
            return
        }
        do {
            if let matchedDonor = try await repository.getOne(donorID) {
                let displayName = matchedDonor.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (matchedDonor.company ?? "ID: \(donorID)") : matchedDonor.fullName
                let address = [matchedDonor.address, matchedDonor.city, matchedDonor.state].compactMap { $0 }.joined(separator: ", ")
                rows[rowIndex].displayInfo = "\(displayName)\n\(address)".trimmingCharacters(in: .newlines)
                if !rows[rowIndex].hasPledgeOverride {
                    rows[rowIndex].pledgeOverride = self.globalPledgeAmount
                }
                rows[rowIndex].pledgeStatusOverride = self.globalPledgeStatus
                rows[rowIndex].expectedFulfillmentDate = self.globalExpectedFulfillmentDate
                rows[rowIndex].isValidDonor = true
                rows[rowIndex].processStatus = .none
                
                // Add a new row and shift focus AFTER updating the current one
                await MainActor.run {
                    // Only add a new row if this is the LAST row
                    if rowIndex == rows.count - 1 {
                        addRow()
                        focusedRowID = rows.last?.id // Focus the newly added row
                        print("Added new row automatically. Focusing \(focusedRowID?.uuidString ?? "nil")")
                    } else {
                        // If not the last row, maybe focus the next row?
                        focusedRowID = rows[rowIndex + 1].id
                        print("Focusing next existing row: \(focusedRowID?.uuidString ?? "nil")")
                    }
                }
                
            } else {
                print("Donor ID \(donorID) not found.")
                // Update row ON MAIN THREAD
                await MainActor.run {
                    rows[rowIndex].displayInfo = "Donor ID \(donorID) not found"
                    rows[rowIndex].isValidDonor = false
                }
            }
        } catch {
            print("Error finding donor \(donorID): \(error)")
            // Update row ON MAIN THREAD
            await MainActor.run {
                rows[rowIndex].displayInfo = "Error finding donor: \(error.localizedDescription)"
                rows[rowIndex].isValidDonor = false
            }
        }
    }
    
    func setDonorFromSearch(_ donor: Donor, for rowID: UUID) async {
        guard let rowIndex = rows.firstIndex(where: { $0.id == rowID }), let donorID = donor.id else {
            print("Error: Could not find row \(rowID) or donor \(donor.id ?? -1) has no ID")
            return
        }
        print("Setting donor from search for row \(rowID): \(donor.fullName)")
        
        await MainActor.run {
            // Set the donor ID from the selected donor
            rows[rowIndex].donorID = donorID
            
            // Update the display info
            let displayName = donor.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (donor.company ?? "ID: \(donorID)") : donor.fullName
            let address = [donor.address, donor.city, donor.state].compactMap { $0 }.joined(separator: ", ")
            
            rows[rowIndex].displayInfo = "\(displayName)\n\(address)".trimmingCharacters(in: .newlines)
            
            // Apply all global defaults when donor is validated
            if !rows[rowIndex].hasPledgeOverride { rows[rowIndex].pledgeOverride = self.globalPledgeAmount }
            rows[rowIndex].pledgeStatusOverride = self.globalPledgeStatus
            rows[rowIndex].expectedFulfillmentDate = self.globalExpectedFulfillmentDate
            
            rows[rowIndex].isValidDonor = true
            rows[rowIndex].processStatus = .none // Reset process status
            
            // Add a new row and shift focus if it's the last row
            if rowIndex == rows.count - 1 {
                addRow()
                focusedRowID = rows.last?.id
                print("Added new row automatically after search selection. Focusing \(focusedRowID?.uuidString ?? "nil")")
            } else {
                focusedRowID = rows[rowIndex + 1].id
                print("Focusing next existing row after search selection: \(focusedRowID?.uuidString ?? "nil")")
            }
        }
    }
    
    func saveBatchPledges(selectedCampaignId: Int?) async -> (success: Int, failed: Int, totalAmount: Double) {
        var successfulPledgesCount = 0
        var totalPledgeAmount: Double = 0
        var failedPledgesCount = 0
        for index in rows.indices {
            guard rows[index].isValidDonor, let donorID = rows[index].donorID else {
                if rows[index].donorID != nil && !rows[index].isValidDonor {
                    rows[index].processStatus = .failure(message: "Donor not validated")
                    failedPledgesCount += 1
                }
                continue
            }
            let pledgeAmount = rows[index].hasPledgeOverride ? rows[index].pledgeOverride : globalPledgeAmount
            guard pledgeAmount > 0 else {
                rows[index].processStatus = .failure(message: "Amount is zero")
                failedPledgesCount += 1
                continue
            }
            print("Simulating save for Pledge: Donor ID \(donorID), Amount: \(pledgeAmount), Campaign: \(selectedCampaignId ?? 0)")
            if Bool.random() || mockDonors.count < 2 {
                rows[index].processStatus = .success
                successfulPledgesCount += 1
                totalPledgeAmount += pledgeAmount
            } else {
                rows[index].processStatus = .failure(message: "Simulated save error")
                failedPledgesCount += 1
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return (successfulPledgesCount, failedPledgesCount, totalPledgeAmount)
    }
    
    func searchMockDonors(query: String) -> [Donor] {
        if query.isEmpty { return [] }
        return mockDonors.filter {
            ($0.firstName?.localizedCaseInsensitiveContains(query) ?? false) ||
            ($0.lastName?.localizedCaseInsensitiveContains(query) ?? false) ||
            ($0.company?.localizedCaseInsensitiveContains(query) ?? false) ||
            ($0.address?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    func getDonor(by id: Int?) -> Donor? {
        guard let donorId = id else { return nil }
        return mockDonors.first(where: { $0.id == donorId })
    }
}
