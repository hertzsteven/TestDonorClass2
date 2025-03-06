//
//  BatchDonationViewModel.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/11/25.
//


import Foundation

// MARK: - ViewModel
class BatchDonationViewModel: ObservableObject {
    
    enum RowProcessStatus {
        case none
        case success
        case failure(message: String)
    }
    
    @Published var globalDonation: Double = 10.0
    @Published var globalDonationType: DonationType = .check
    @Published var globalPaymentStatus: PaymentStatus = .completed
    
    // Each row in the list
    @Published var rows: [RowEntry] = []
    
    // Keep track of which row we should focus next
    @Published var focusedRowID: UUID? = nil
        // MARK: - Private Properties
        private let repository: any DonorSpecificRepositoryProtocol
        private let donationRepository: any DonationSpecificRepositoryProtocol
        
//        // MARK: - Initialization
//        init(repository: DonorRepository = DonorRepository()) {
//            self.repository = repository
//        }
    init(repository: DonorRepository = DonorRepository(), donationRepository: DonationRepository = DonationRepository()) {
        self.repository = repository
        self.donationRepository = donationRepository
            // Start with one row
        rows.append(RowEntry())
    }
    
    struct RowEntry: Identifiable {
        let id = UUID()
        var donorID: Int? = nil
        var displayInfo: String = ""
        var donationOverride:  Double = 0.0
        var printReceipt: Bool = false
        var donationTypeOverride: DonationType  = .check
        var paymentStatusOverride: PaymentStatus = .completed
        var isValidDonor: Bool = false
        var processStatus: RowProcessStatus = .none
    }
    
    /// Adds a new blank row at the bottom
    func addRow() {
        rows.append(RowEntry())
    }
    
    
    func getDonor(_ id: Int) async throws -> Donor? {
        let donor = try await repository.getOne(id)
        return donor
    }
    
    func addDonation(_ donation: Donation) async throws {
        try await donationRepository.insert(donation)
    }
    
    /// Attempt to find a donor by ID, then mark the row with success/failure.
    /// Pass in `DonorObjectClass` so we can call the real DB.
    func findDonor(for rowID: UUID) async {
        guard let rowIndex = rows.firstIndex(where: { $0.id == rowID }) else { return }
        guard let donorID = rows[rowIndex].donorID else { return }
        
        do {
            // Attempt a real DB fetch:
            if let matchedDonor = try await repository.getOne(donorID) {
//            if let matchedDonor = try await donorObject.getDonor(donorID) {
                let displayName = "\(matchedDonor.company ?? "") \(matchedDonor.lastName ?? "") \(matchedDonor.firstName ?? "")"
                let address = matchedDonor.address ?? ""
                
                // Update row
                await MainActor.run {
                    rows[rowIndex].displayInfo = "\(displayName) | \(address)"
                    rows[rowIndex].donationOverride = globalDonation
                    rows[rowIndex].printReceipt = false
                    rows[rowIndex].donationTypeOverride = globalDonationType
                    rows[rowIndex].paymentStatusOverride = globalPaymentStatus
                    rows[rowIndex].isValidDonor = true
                }
                
                // Now add a new row and shift focus to it
                await MainActor.run {
                    addRow()
                    focusedRowID = rows.last?.id
                }
            } else {
                // If not found
                await MainActor.run {
                    rows[rowIndex].displayInfo = "Donor not found"
                    rows[rowIndex].donationOverride = 0.0
                    rows[rowIndex].printReceipt = false
                    rows[rowIndex].donationTypeOverride = .check
                    rows[rowIndex].paymentStatusOverride = .completed
                    rows[rowIndex].isValidDonor = false
                }
            }
        } catch {
            // Database error or something else
            await MainActor.run {
                rows[rowIndex].displayInfo = "Error: \(error.localizedDescription)"
                rows[rowIndex].donationOverride = 0.0
                rows[rowIndex].printReceipt = false
                rows[rowIndex].donationTypeOverride = .check
                rows[rowIndex].paymentStatusOverride = .completed
                rows[rowIndex].isValidDonor = false
            }
        }
    }
    
    @MainActor
    func cleearBatch() {
        rows.removeAll()
        rows.append(RowEntry())
        focusedRowID = rows.last?.id
    }
    
    /// Saves each row as a new donation in the DB (optional).
//    func saveBatch(donorObject: DonorObjectClass,
//                   donationObject: DonationObjectClass) async {
//        for row in rows {
//            guard row.isValidDonor,
//                  let donorID = row.donorID,
//                  let matchedDonor = try? await donorObject.getDonor(donorID)
//            else { continue }
//            
//            let donationAmt = (row.donationOverride == 0.0)
//                ? globalDonation
//                : row.donationOverride
//            
////            let donationAmt = Double(donationAmtText) ?? 0.0
//            
//            // Create a new donation
//            var newDonation = Donation(
//                donorId: matchedDonor.id,
//                amount: donationAmt,
//                donationType: .cash,  // or .check, etc.
//                donationDate: Date()
//            )
//            
//            do {
//                // Insert into your DB
//                try await donationObject.addDonation(newDonation)
//            } catch {
//                print("Failed saving donation for donor \(donorID): \(error)")
//            }
//        }
//        
//        // Optionally, clear or reset
//        await MainActor.run {
//            rows = [RowEntry()] // back to one empty row
//        }
//    }
}
