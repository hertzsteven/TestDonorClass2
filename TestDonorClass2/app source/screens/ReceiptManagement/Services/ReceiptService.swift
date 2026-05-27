//
//  ReceiptService.swift
//  TestDonorClass2
//
//  Owns all receipt-related I/O and donation→DonationInfo mapping.
//  Pure async/await — no callback APIs, no GCD. ViewModels depend on
//  this service via initializer injection so it can be mocked in tests.
//

import Foundation

final class ReceiptService {
    private let donationRepository: DonationRepository
    private let printBatchRepository: PrintBatchRepository
    private let printingService: ReceiptPrintingService
    private let settingsProvider: () -> ReceiptOutputMode

    init(
        donationRepository: DonationRepository,
        printBatchRepository: PrintBatchRepository = PrintBatchRepository(),
        printingService: ReceiptPrintingService = ReceiptPrintingService(),
        settingsProvider: @escaping () -> ReceiptOutputMode = {
            OrganizationSettingsManager().receiptOutputMode
        }
    ) {
        self.donationRepository = donationRepository
        self.printBatchRepository = printBatchRepository
        self.printingService = printingService
        self.settingsProvider = settingsProvider
    }

    // MARK: - Loading

    func loadReceipts(status: ReceiptStatus) async throws -> [ReceiptItem] {
        let donations = try await donationRepository.getReceiptRequests(status: status)
        return try await convertToReceiptItems(donations)
    }

    func loadStatusCounts() async -> [ReceiptStatus: Int] {
        var counts: [ReceiptStatus: Int] = [:]
        for status in ReceiptStatus.allCases {
            counts[status] = (try? await donationRepository.countReceiptsByStatus(status)) ?? 0
        }
        return counts
    }

    // MARK: - Status mutations

    func updateStatus(donationId: Int, to status: ReceiptStatus) async throws {
        try await donationRepository.updateReceiptStatus(donationId: donationId, status: status)
    }

    func bulkPromoteToRequested(minAmount: Double) async throws -> Int {
        try await donationRepository.bulkUpdateToRequested(minAmount: minAmount)
    }

    func revertBatch(batchId: Int) async throws {
        try await printBatchRepository.revertBatch(batchId: batchId)
    }

    // MARK: - Printing

    /// Prints a batch of receipts in a single print job, updating each
    /// receipt's status based on the outcome.
    /// Returns a tuple of (printed, cancelled, failed).
    @MainActor
    func batchPrint(_ receipts: [ReceiptItem]) async -> (printed: Int, cancelled: Int, failed: Int) {
        for receipt in receipts {
            try? await updateStatus(donationId: receipt.donationId, to: .queued)
        }

        var donationInfos: [DonationInfo] = []
        for receipt in receipts {
            if let info = await donationInfo(for: receipt) {
                donationInfos.append(info)
            }
        }

        guard !donationInfos.isEmpty else {
            for receipt in receipts {
                try? await updateStatus(donationId: receipt.donationId, to: .failed)
            }
            return (printed: 0, cancelled: 0, failed: receipts.count)
        }

        let success = await printingService.printReceipts(
            for: donationInfos,
            mode: settingsProvider()
        )

        if success {
            do {
                _ = try await printBatchRepository.createBatch(
                    donationIds: receipts.map(\.donationId),
                    label: nil
                )
            } catch {
                for receipt in receipts {
                    try? await updateStatus(donationId: receipt.donationId, to: .printed)
                }
            }
            return (printed: receipts.count, cancelled: 0, failed: 0)
        } else {
            for receipt in receipts {
                try? await updateStatus(donationId: receipt.donationId, to: .requested)
            }
            return (printed: 0, cancelled: receipts.count, failed: 0)
        }
    }

    /// Prints a test receipt with hard-coded sample data.
    /// Returns whether the print dialog completed successfully.
    @MainActor
    func printTestReceipt() async -> Bool {
        let dateString = Date().formatted(date: .abbreviated, time: .omitted)
        let info = DonationInfo(
            donorName: "John Doe",
            donorTitle: "Mr.",
            donationAmount: 100.00,
            date: dateString,
            donorAddress: "123 Main Street",
            donorCity: "New York",
            donorState: "NY",
            donorZip: "10001",
            receiptNumber: "TEST-001"
        )
        return await printingService.printReceipt(for: info, mode: settingsProvider())
    }

    // MARK: - Mapping helpers

    private func convertToReceiptItems(_ donations: [Donation]) async throws -> [ReceiptItem] {
        var items: [ReceiptItem] = []
        items.reserveCapacity(donations.count)
        for donation in donations {
            let donorName = await donorDisplayName(for: donation)
            let campaignName = await campaignDisplayName(for: donation)
            items.append(
                ReceiptItem(
                    donationId: donation.id ?? 0,
                    donorName: donorName,
                    amount: donation.amount,
                    date: donation.donationDate,
                    campaignName: campaignName,
                    status: donation.receiptStatus,
                    printBatchId: donation.printBatchId,
                    printedAt: donation.printedAt
                )
            )
        }
        return items
    }

    private func donorDisplayName(for donation: Donation) async -> String {
        guard let donorId = donation.donorId, !donation.isAnonymous,
              let donor = try? await donationRepository.getDonorForDonation(donorId: donorId) else {
            return "Anonymous"
        }
        let combined = "\(donor.firstName ?? "") \(donor.lastName ?? "")"
        let trimmed = combined.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return donor.company ?? "Unknown"
        }
        return trimmed
    }

    private func campaignDisplayName(for donation: Donation) async -> String? {
        guard let campaignId = donation.campaignId,
              let campaign = try? await donationRepository.getCampaignForDonation(campaignId: campaignId) else {
            return nil
        }
        return campaign.name
    }

    /// Builds the full DonationInfo (including donor address) for printing.
    /// Returns nil if the underlying donation cannot be loaded.
    private func donationInfo(for receipt: ReceiptItem) async -> DonationInfo? {
        guard let donation = try? await donationRepository.getOne(receipt.donationId) else {
            return nil
        }

        var donorName = "Anonymous"
        var donorTitle: String?
        var donorAddress: String?
        var donorCity: String?
        var donorState: String?
        var donorZip: String?

        if let donorId = donation.donorId, !donation.isAnonymous,
           let donor = try? await donationRepository.getDonorForDonation(donorId: donorId) {
            let combined = "\(donor.firstName ?? "") \(donor.lastName ?? "")"
            let trimmed = combined.trimmingCharacters(in: .whitespaces)
            donorName = trimmed.isEmpty ? (donor.company ?? "Unknown") : trimmed
            donorTitle = donor.salutation
            donorAddress = DonorAddressFormatter.formatStreetLine(
                address: donor.address,
                suite: donor.suite,
                additionalLine: donor.addl_line
            )
            donorCity = donor.city
            donorState = donor.state
            donorZip = donor.zip
        }

        let dateString = donation.donationDate.formatted(date: .abbreviated, time: .omitted)

        return DonationInfo(
            donorName: donorName,
            donorTitle: donorTitle,
            donationAmount: donation.amount,
            date: dateString,
            donorAddress: donorAddress,
            donorCity: donorCity,
            donorState: donorState,
            donorZip: donorZip,
            receiptNumber: donation.receiptNumber
        )
    }
}
