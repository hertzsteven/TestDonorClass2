//
//  BatchDonationViewModel.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/11/25.
//

import Foundation
import SwiftUI // Added for RowEntry potentially needing SwiftUI types later

// MARK: - ViewModel
@MainActor // Good practice for ViewModels updating UI
class BatchDonationViewModel: ObservableObject {

    enum RowProcessStatus: Equatable { // Add Equatable for potential comparisons
        case none
        case success
        case failure(message: String)
    }

    @Published var globalDonation: Double = 10.0
    @Published var globalDonationType: DonationType = .check
    @Published var globalPaymentStatus: PaymentStatus = .completed
    @Published var globalPrintReceipt: Bool = false
    @Published var globalDonationDate: Date = Date()

    @Published var rows: [RowEntry] = []
    @Published var focusedRowID: UUID? = nil // Keep track of which row should get focus

    // MARK: - Private Properties
    // Use protocols and remove default values
    private let repository: any DonorSpecificRepositoryProtocol
    private let donationRepository: any DonationSpecificRepositoryProtocol

    // MARK: - Initialization
    init(
        repository: any DonorSpecificRepositoryProtocol,
        donationRepository: any DonationSpecificRepositoryProtocol
    ) {
        self.repository = repository
        self.donationRepository = donationRepository
        // Start with one row
        addRow() // Call addRow to ensure there's an initial row
        // Set initial focus? Optional.
        // self.focusedRowID = rows.first?.id
        print("BatchDonationViewModel Initialized")
    }

    // Define RowEntry struct within the ViewModel or globally if used elsewhere
    struct RowEntry: Identifiable {
        let id = UUID()
        var donorID: Int? = nil
        var lastNameSearch: String = ""
        var displayInfo: String = ""
        var donationOverride: Double = 0.0 // Use Double
        var printReceipt: Bool = false
        var prayerNoteSW: Bool = false
        var prayerNote: String? = nil
        var donationTypeOverride: DonationType = .check // Default to global? Or separate?
        var paymentStatusOverride: PaymentStatus = .completed // Default to global? Or separate?
        var isValidDonor: Bool = false
        var processStatus: RowProcessStatus = .none

        // Convenience computed property to check if override is set
        var hasDonationOverride: Bool { donationOverride > 0.0 }
    }

    // MARK: - Public Methods

    /// Adds a new blank row at the bottom
    func addRow() {
        let newRow = RowEntry(
            donationTypeOverride: self.globalDonationType,
            paymentStatusOverride: self.globalPaymentStatus
            // printReceipt will use its default false value
        )
        rows.append(newRow)
        print("Added new row. Total rows: \(rows.count)")
        // Optionally set focus to the new row immediately
        // self.focusedRowID = newRow.id
    }

    /// Clears all rows and adds a single new one
    func clearBatch() {
        rows.removeAll()
        addRow() // Add the initial row back
        focusedRowID = rows.first?.id // Focus the new row
        print("Cleared batch. Added initial row.")
    }


    /// Attempt to find a donor by ID, then mark the row with success/failure.
    func findDonor(for rowID: UUID) async {
        guard let rowIndex = rows.firstIndex(where: { $0.id == rowID }) else {
            print("Error: Could not find row with ID \(rowID)")
            return
        }
        guard let donorID = rows[rowIndex].donorID else {
             print("Error: No Donor ID entered for row \(rowID)")
             // Optionally provide feedback to the UI
             await MainActor.run {
                 rows[rowIndex].displayInfo = "Please enter a Donor ID"
                 rows[rowIndex].isValidDonor = false
             }
            return
        }
         print("Finding donor for ID \(donorID) in row \(rowID)")

        do {
            if let matchedDonor = try await repository.getOne(donorID) {
                print("Donor found: \(matchedDonor.fullName)")
                let displayName = matchedDonor.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (matchedDonor.company ?? "ID: \(donorID)") : matchedDonor.fullName
                let address = [matchedDonor.address, matchedDonor.city, matchedDonor.state].compactMap { $0 }.joined(separator: ", ")

                let fullDisplayInfo = address.isEmpty ? displayName : "\(displayName)\n\(address)"
                await MainActor.run {
                    rows[rowIndex].displayInfo = fullDisplayInfo
                    rows[rowIndex].lastNameSearch = ""
                    rows[rowIndex].isValidDonor = true
                    rows[rowIndex].processStatus = .none
                    if !rows[rowIndex].hasDonationOverride {
                        rows[rowIndex].donationOverride = self.globalDonation
                    }
                    rows[rowIndex].donationTypeOverride = self.globalDonationType
                    rows[rowIndex].paymentStatusOverride = self.globalPaymentStatus
                    rows[rowIndex].printReceipt = self.globalPrintReceipt
                }
                await MainActor.run {
                    if rowIndex == rows.count - 1 {
                        addRow()
                        focusedRowID = rows.last?.id
                        print("Added new row automatically. Focusing \(focusedRowID?.uuidString ?? "nil")")
                    } else {
                        focusedRowID = rows[rowIndex + 1].id
                        print("Focusing next existing row: \(focusedRowID?.uuidString ?? "nil")")
                    }
                }
            } else {
                 print("Donor ID \(donorID) not found.")
                await MainActor.run {
                    rows[rowIndex].displayInfo = "Donor ID \(donorID) not found"
                    rows[rowIndex].isValidDonor = false
                }
            }
        } catch {
            print("Error finding donor \(donorID): \(error)")
            await MainActor.run {
                rows[rowIndex].displayInfo = "Error finding donor: \(error.localizedDescription)"
                rows[rowIndex].isValidDonor = false
            }
        }
    }

    /// Handles setting donor info when selected from the search view
    func setDonorFromSearch(_ donor: Donor, for rowID: UUID) async {
        guard let rowIndex = rows.firstIndex(where: { $0.id == rowID }), let donorID = donor.id else {
            print("Error: Could not find row \(rowID) or donor \(donor.id ?? -1) has no ID")
            return
        }
         print("Setting donor from search for row \(rowID): \(donor.fullName)")

        await MainActor.run {
            rows[rowIndex].donorID = donorID
            rows[rowIndex].lastNameSearch = ""
            let displayName = donor.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (donor.company ?? "ID: \(donorID)") : donor.fullName
            let address = [donor.address, donor.city, donor.state].compactMap { $0 }.joined(separator: ", ")
            let fullDisplayInfo = address.isEmpty ? displayName : "\(displayName)\n\(address)"
            rows[rowIndex].displayInfo = fullDisplayInfo
            rows[rowIndex].isValidDonor = true
            rows[rowIndex].processStatus = .none
            if !rows[rowIndex].hasDonationOverride {
                rows[rowIndex].donationOverride = self.globalDonation
            }
            rows[rowIndex].donationTypeOverride = self.globalDonationType
            rows[rowIndex].paymentStatusOverride = self.globalPaymentStatus
            rows[rowIndex].printReceipt = self.globalPrintReceipt
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

    /// Saves valid rows as donations
    func saveBatchDonations(selectedCampaignId: Int?) async -> (success: Int, failed: Int, totalAmount: Double) {
        print("Starting batch save...")
        var successfulDonationsCount = 0
        var totalDonationAmount: Double = 0
        var failedDonationsCount = 0

        let rowsToProcess = rows

        for row in rowsToProcess {
            guard let index = rows.firstIndex(where: { $0.id == row.id }) else { continue }
            
            guard row.isValidDonor, let donorID = row.donorID else {
                if row.donorID != nil && !row.isValidDonor {
                    await MainActor.run { rows[index].processStatus = .failure(message: "Donor not validated") }
                    failedDonationsCount += 1
                }
                continue
            }

            print("Processing row for donor ID \(donorID)")

            let donationAmount = row.hasDonationOverride ? row.donationOverride : globalDonation
            guard donationAmount > 0 else {
                print("Skipping row: Zero donation amount.")
                await MainActor.run { rows[index].processStatus = .failure(message: "Amount is zero") }
                failedDonationsCount += 1
                continue
            }

            let donationType = row.donationTypeOverride
            let paymentStatus = row.paymentStatusOverride
            let printReceipt = row.printReceipt
            let prayerNote = row.prayerNoteSW ? row.prayerNote : nil

            let donation = Donation(
                donorId: donorID,
                campaignId: selectedCampaignId,
                donationIncentiveId: nil,
                amount: donationAmount,
                donationType: donationType,
                paymentStatus: paymentStatus,
                requestEmailReceipt: false,
                requestPrintedReceipt: printReceipt,
                notes: prayerNote,
                isAnonymous: false,
                donationDate: globalDonationDate
            )

            do {
                try await donationRepository.insert(donation)
                print("Successfully saved donation for donor \(donorID), amount: \(donationAmount)")
                await MainActor.run { rows[index].processStatus = .success }
                successfulDonationsCount += 1
                totalDonationAmount += donationAmount
            } catch {
                print("Error saving donation for donor \(donorID): \(error)")
                await MainActor.run { rows[index].processStatus = .failure(message: error.localizedDescription) }
                failedDonationsCount += 1
            }
        }

        print("Batch save complete. Success: \(successfulDonationsCount), Failed: \(failedDonationsCount), Total Amount: \(totalDonationAmount)")
        return (successfulDonationsCount, failedDonationsCount, totalDonationAmount)
    }

     func getDonor(_ id: Int) async throws -> Donor? {
         try await repository.getOne(id)
     }

     func addDonation(_ donation: Donation) async throws {
         try await donationRepository.insert(donation)
     }
}