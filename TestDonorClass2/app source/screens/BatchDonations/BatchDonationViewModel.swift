//
//  BatchDonationViewModel.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/11/25.
//

import Foundation
import SwiftUI

@MainActor
class BatchDonationViewModel: ObservableObject {

    enum RowProcessStatus: Equatable {
        case none
        case success
        case failure(message: String)
    }

    struct RowEntry: Identifiable {
        let id = UUID()
        var donorID: Int? = nil
        var lastNameSearch: String = ""
        var displayInfo: String = ""
        var donationOverride: Double = 0.0
        var printReceipt: Bool = false
        var prayerNoteSW: Bool = false
        var prayerNote: String? = nil
        var donationTypeOverride: DonationType = .check
        var paymentStatusOverride: PaymentStatus = .completed
        var isValidDonor: Bool = false
        var processStatus: RowProcessStatus = .none
        var hasDonationOverride: Bool { donationOverride > 0.0 }
    }

    @Published var globalDonation: Double = 10.0
    @Published var globalDonationType: DonationType = .check
    @Published var globalPaymentStatus: PaymentStatus = .completed
    @Published var globalPrintReceipt: Bool = false
    @Published var globalDonationDate: Date = Date()
    @Published var rows: [RowEntry] = []
    @Published var focusedRowID: UUID? = nil

    private let repository: any DonorSpecificRepositoryProtocol
    private let donationRepository: any DonationSpecificRepositoryProtocol

    init(repository: any DonorSpecificRepositoryProtocol, donationRepository: any DonationSpecificRepositoryProtocol) {
        self.repository = repository
        self.donationRepository = donationRepository
        addRow()
        print("BatchDonationViewModel Initialized")
    }

    func addRow() {
        let newRow = RowEntry(
            donationTypeOverride: self.globalDonationType,
            paymentStatusOverride: self.globalPaymentStatus
        )
        rows.append(newRow)
        print("Added new row. Total rows: \(rows.count)")
    }

    func clearBatch() {
        print("Cleared batch. Replacing with a single initial row.")
        let newRow = RowEntry(
            donationTypeOverride: self.globalDonationType,
            paymentStatusOverride: self.globalPaymentStatus
        )
        self.rows = [newRow]
        self.focusedRowID = self.rows.first?.id
    }

    func findDonor(for rowID: UUID) async {
        guard let rowIndex = rows.firstIndex(where: { $0.id == rowID }) else {
            print("Error: Could not find row with ID \(rowID)")
            return
        }
        guard let donorID = rows[rowIndex].donorID else {
            rows[rowIndex].displayInfo = "Please enter a Donor ID"
            rows[rowIndex].isValidDonor = false
            return
        }
        print("Finding donor for ID \(donorID) in row \(rowID)")

        do {
            if let matchedDonor = try await repository.getOne(donorID) {
                print("Donor found: \(matchedDonor.fullName)")
                let displayName = matchedDonor.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (matchedDonor.company ?? "ID: \(donorID)") : matchedDonor.fullName
                let address = [matchedDonor.address, matchedDonor.city, matchedDonor.state].compactMap { $0 }.joined(separator: ", ")
                let fullDisplayInfo = address.isEmpty ? displayName : "\(displayName)\n\(address)"
                
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

                if rowIndex == rows.count - 1 {
                    addRow()
                    focusedRowID = rows.last?.id
                } else {
                    focusedRowID = rows[rowIndex + 1].id
                }
            } else {
                print("Donor ID \(donorID) not found.")
                rows[rowIndex].displayInfo = "Donor ID \(donorID) not found"
                rows[rowIndex].isValidDonor = false
            }
        } catch {
            print("Error finding donor \(donorID): \(error)")
            rows[rowIndex].displayInfo = "Error finding donor: \(error.localizedDescription)"
            rows[rowIndex].isValidDonor = false
        }
    }

    func setDonorFromSearch(_ donor: Donor, for rowID: UUID) async {
        guard let rowIndex = rows.firstIndex(where: { $0.id == rowID }), let donorID = donor.id else {
            print("Error: Could not find row \(rowID) or donor has no ID")
            return
        }
        print("Setting donor from search for row \(rowID): \(donor.fullName)")

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
        } else {
            focusedRowID = rows[rowIndex + 1].id
        }
    }

    func saveBatchDonations(selectedCampaignId: Int?) async -> (success: Int, failed: Int, totalAmount: Double) {
        print("Starting batch save...")
        var successfulDonationsCount = 0
        var totalDonationAmount: Double = 0
        var failedDonationsCount = 0

        var updatedRows = self.rows

        for i in updatedRows.indices {
            let row = updatedRows[i]
            
            guard row.isValidDonor, let donorID = row.donorID else {
                if row.donorID != nil && !row.isValidDonor {
                    updatedRows[i].processStatus = .failure(message: "Donor not validated")
                    failedDonationsCount += 1
                }
                continue
            }

            print("Processing row for donor ID \(donorID)")

            let donationAmount = row.hasDonationOverride ? row.donationOverride : globalDonation
            guard donationAmount > 0 else {
                print("Skipping row: Zero donation amount.")
                updatedRows[i].processStatus = .failure(message: "Amount is zero")
                failedDonationsCount += 1
                continue
            }

            let donation = Donation(
                donorId: donorID,
                campaignId: selectedCampaignId,
                amount: donationAmount,
                donationType: row.donationTypeOverride,
                paymentStatus: row.paymentStatusOverride,
                requestPrintedReceipt: row.printReceipt,
                notes: row.prayerNoteSW ? row.prayerNote : nil,
                donationDate: globalDonationDate
            )

            do {
                _ = try await donationRepository.insert(donation)
                print("Successfully saved donation for donor \(donorID), amount: \(donationAmount)")
                updatedRows[i].processStatus = .success
                successfulDonationsCount += 1
                totalDonationAmount += donationAmount
            } catch {
                print("Error saving donation for donor \(donorID): \(error)")
                updatedRows[i].processStatus = .failure(message: error.localizedDescription)
                failedDonationsCount += 1
            }
        }
        
        self.rows = updatedRows

        print("Batch save complete. Success: \(successfulDonationsCount), Failed: \(failedDonationsCount), Total Amount: \(totalDonationAmount)")
        return (successfulDonationsCount, failedDonationsCount, totalDonationAmount)
    }

    func getDonor(_ id: Int) async throws -> Donor? {
        try await repository.getOne(id)
    }

    func addDonation(_ donation: Donation) async throws {
        _ = try await donationRepository.insert(donation)
    }
}