//
//  ReceiptManagementViewModel.swift
//  TestDonorClass2
//
//  Coordinates receipt UI state. Owns lists, counts, filter results,
//  and the currently-tapped row. All I/O goes through ReceiptService.
//

import Foundation

@MainActor
@Observable
final class ReceiptManagementViewModel {
    private(set) var allReceipts: [ReceiptItem] = []
    private(set) var filteredReceipts: [ReceiptItem] = []
    private(set) var statusCounts: [ReceiptStatus: Int] = [:]
    private(set) var isLoading = false
    private(set) var currentStatus: ReceiptStatus = .requested

    var selectedReceipt: ReceiptItem?
    private(set) var maxReceiptsPerPrint: Int = ReceiptManagementViewModel.readMaxFromSettings()

    /// Current filter inputs, mirrored from the view via `applyFilters(...)`.
    /// Tracked here so they can be re-applied automatically after every
    /// data refresh (e.g. after Mark as Printed mutates the list).
    private var currentSearchText = ""
    private var currentMinAmount: Double?
    private var currentMaxAmount: Double?

    private let service: ReceiptService

    var isGroupingByBatch: Bool {
        PrintBatchGroup.shouldGroup(
            status: currentStatus,
            searchText: currentSearchText,
            minAmount: currentMinAmount,
            maxAmount: currentMaxAmount
        )
    }

    var printedBatchGroups: [PrintBatchGroup] {
        PrintBatchGroup.buildGroups(from: filteredReceipts)
    }

    init(service: ReceiptService) {
        self.service = service
    }

    /// Convenience initializer that builds the default service stack.
    /// Throws if the underlying repository can't be opened.
    convenience init() throws {
        let repository = try DonationRepository()
        self.init(service: ReceiptService(donationRepository: repository))
    }

    // MARK: - Loading

    func loadReceipts(status: ReceiptStatus) async {
        isLoading = true
        defer { isLoading = false }

        currentStatus = status
        maxReceiptsPerPrint = Self.readMaxFromSettings()

        do {
            let items = try await service.loadReceipts(status: status)
            allReceipts = items
        } catch {
            print("Error loading receipts: \(error)")
            allReceipts = []
        }

        reapplyCurrentFilters()
    }

    func loadStatusCounts() async {
        statusCounts = await service.loadStatusCounts()
    }

    func refresh(status: ReceiptStatus) async {
        await loadReceipts(status: status)
        await loadStatusCounts()
    }

    // MARK: - Filtering

    func applyFilters(searchText: String, minAmount: Double?, maxAmount: Double?) {
        currentSearchText = searchText
        currentMinAmount = minAmount
        currentMaxAmount = maxAmount
        reapplyCurrentFilters()
    }

    /// Recomputes `filteredReceipts` from `allReceipts` using the most
    /// recently supplied filter inputs. Called both from view-driven
    /// filter edits and after server data refreshes so the visible list
    /// always reflects the active filter.
    private func reapplyCurrentFilters() {
        var results = allReceipts

        if !currentSearchText.isEmpty {
            results = results.filter { receipt in
                receipt.donorName.localizedStandardContains(currentSearchText)
                    || (receipt.campaignName?.localizedStandardContains(currentSearchText) ?? false)
                    || String(receipt.donationId).contains(currentSearchText)
            }
        }
        if let minAmount = currentMinAmount {
            results = results.filter { $0.amount >= minAmount }
        }
        if let maxAmount = currentMaxAmount {
            results = results.filter { $0.amount <= maxAmount }
        }

        filteredReceipts = results
    }

    // MARK: - Status mutations (called from row swipe actions)

    func markAsPrinted(_ receipt: ReceiptItem) async {
        await updateStatus(donationId: receipt.donationId, to: .printed, refreshStatus: currentStatus)
    }

    func markAsRequested(_ receipt: ReceiptItem) async {
        await updateStatus(donationId: receipt.donationId, to: .requested, refreshStatus: currentStatus)
    }

    func revertBatch(_ group: PrintBatchGroup) async {
        guard let batchId = group.batch?.id else { return }
        do {
            try await service.revertBatch(batchId: batchId)
            await refresh(status: currentStatus)
        } catch {
            print("Error reverting print batch \(batchId): \(error)")
        }
    }

    /// Marks every receipt in the supplied list as Printed without
    /// invoking the print dialog. Used for the bulk "Mark as Printed"
    /// action driven from the action bar.
    func markBatchAsPrinted(_ receipts: [ReceiptItem]) async {
        for receipt in receipts {
            do {
                try await service.updateStatus(
                    donationId: receipt.donationId,
                    to: .printed
                )
            } catch {
                print("Error marking \(receipt.donationId) as printed: \(error)")
            }
        }
        await refresh(status: .requested)
    }

    // MARK: - Bulk operations

    func bulkPromoteToRequested(minAmount: Double, fromStatus: ReceiptStatus) async -> Int {
        do {
            let count = try await service.bulkPromoteToRequested(minAmount: minAmount, fromStatus: fromStatus)
            await loadStatusCounts()
            return count
        } catch {
            print("Error in bulk update: \(error)")
            return 0
        }
    }

    // MARK: - Private helpers

    private func updateStatus(
        donationId: Int,
        to status: ReceiptStatus,
        refreshStatus: ReceiptStatus = .requested
    ) async {
        do {
            try await service.updateStatus(donationId: donationId, to: status)
            await refresh(status: refreshStatus)
        } catch {
            print("Error updating receipt status to \(status): \(error)")
        }
    }

    private static func readMaxFromSettings() -> Int {
        let value = UserDefaults.standard.integer(forKey: "maxReceiptsPerPrint")
        return value == 0 ? 10 : value
    }
}
