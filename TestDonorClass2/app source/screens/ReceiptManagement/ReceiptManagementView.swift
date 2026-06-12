//
//  ReceiptManagementView.swift
//  TestDonorClass2
//
//  Top-level container for the Receipts screen. Composes the status
//  picker, filter card, list, and action bar; coordinates the print
//  sheet and the bulk-update bar. All business logic lives in
//  ReceiptManagementViewModel and ReceiptService.
//

import SwiftUI

struct ReceiptManagementView: View {
    @State private var viewModel: ReceiptManagementViewModel
    private let service: ReceiptService

    @State private var selectedStatus: ReceiptStatus = .requested
    @State private var searchText = ""
    @State private var minAmount: Double?
    @State private var maxAmount: Double?
    @State private var selectedReceipts: Set<UUID> = []
    @State private var overrideMaxReceipts: Int?
    @State private var bulkUpdateThreshold = "100"

    @State private var showingPrintSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var pendingPrintAlertMessage: String?
    @State private var totalReceiptsForPrint = 0

    @State private var showingBulkUpdateAlert = false
    @State private var bulkUpdateCount = 0

    @State private var showingMarkPrintedConfirm = false
    @State private var batchPendingRevert: PrintBatchGroup?
    @State private var showingRevertBatchConfirm = false
    @State private var receiptForDetail: ReceiptItem?

    /// Bumped whenever a row is promoted/demoted via swipe so the user
    /// gets a brief success haptic as the row leaves the current list.
    @State private var statusChangeTrigger = 0

    init() {
        let service: ReceiptService
        do {
            let repository = try DonationRepository()
            service = ReceiptService(donationRepository: repository)
        } catch {
            fatalError("Unable to open DonationRepository: \(error)")
        }
        self.service = service
        _viewModel = State(initialValue: ReceiptManagementViewModel(service: service))
    }

    private var effectiveMaxReceipts: Int {
        overrideMaxReceipts ?? viewModel.maxReceiptsPerPrint
    }

    private var hasActiveFilter: Bool {
        !searchText.isEmpty || minAmount != nil || maxAmount != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $selectedStatus) {
                ForEach(ReceiptStatus.allCases, id: \.self) { status in
                    Text("\(status.displayName) (\(viewModel.statusCounts[status] ?? 0))")
                        .tag(status)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedStatus == .notRequested || selectedStatus == .digitallySent {
                BulkUpdateBarView(
                    threshold: $bulkUpdateThreshold,
                    onSubmit: handleBulkUpdate
                )
            }

            ReceiptFiltersView(
                searchText: $searchText,
                minAmount: $minAmount,
                maxAmount: $maxAmount,
                onChange: applyFilters
            )
            .padding(.bottom, 4)

            ActiveFilterChipsView(
                minAmount: minAmount,
                maxAmount: maxAmount,
                onClear: clearAmountFilter
            )

            ReceiptContentView(
                isLoading: viewModel.isLoading,
                receipts: viewModel.filteredReceipts,
                printedBatchGroups: viewModel.printedBatchGroups,
                isGroupingByBatch: viewModel.isGroupingByBatch,
                selectedReceipts: selectedReceipts,
                status: selectedStatus,
                hasActiveFilter: hasActiveFilter,
                effectiveMaxReceipts: effectiveMaxReceipts,
                onToggleSelection: toggleSelection,
                onPrintRow: printSingleRow,
                onMarkPrinted: markRowAsPrinted,
                onMarkRequested: markRowAsRequested,
                onMarkNotRequested: markRowAsNotRequested,
                onRevertBatch: prepareRevertBatch,
                onViewDetails: { receiptForDetail = $0 },
                onDeselectAll: { selectedReceipts.removeAll() },
                onTestPrint: handleTestPrint,
                onRefresh: { Task { await viewModel.refresh(status: selectedStatus) } },
                onChangeMax: { overrideMaxReceipts = $0 },
                onPrintAll: handlePrintAll,
                onMarkSelectedPrinted: { showingMarkPrintedConfirm = true }
            )
        }
        .navigationTitle("Receipts")
        .sensoryFeedback(.success, trigger: statusChangeTrigger)
        .alert("Receipt Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .alert("Bulk Update Complete", isPresented: $showingBulkUpdateAlert) {
            Button("OK") {
                if bulkUpdateCount > 0 {
                    selectedStatus = .requested
                }
            }
        } message: {
            Text(bulkUpdateMessage)
        }
        .confirmationDialog(
            "Mark \(selectedReceipts.count) receipt(s) as printed?",
            isPresented: $showingMarkPrintedConfirm,
            titleVisibility: .visible
        ) {
            Button("Mark as Printed", role: .destructive, action: handleMarkSelectedPrinted)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("They will move to the Printed tab. The print dialog will not open.")
        }
        .alert(
            "Revert \(batchPendingRevert?.receipts.count ?? 0) receipt(s)?",
            isPresented: $showingRevertBatchConfirm
        ) {
            Button("Revert to Requested", role: .destructive, action: confirmRevertBatch)
            Button("Cancel", role: .cancel) {
                batchPendingRevert = nil
            }
        } message: {
            Text("All receipts in this print batch will return to the Requested tab so you can reprint them.")
        }
        .sheet(isPresented: $showingPrintSheet, onDismiss: presentPendingAlertIfNeeded) {
            PrintReceiptSheetView(
                receipts: receiptsToPrint(),
                service: service,
                onCompletion: handlePrintCompletion
            )
            .interactiveDismissDisabled()
        }
        .sheet(item: $receiptForDetail) { receipt in
            if let repository = try? DonationRepository() {
                ReceiptDetailSheetView(
                    receiptItem: receipt,
                    donationRepository: repository
                )
                .interactiveDismissDisabled()
            }
        }
        .onAppear {
            overrideMaxReceipts = nil
            Task { await viewModel.refresh(status: selectedStatus) }
        }
        .onChange(of: selectedStatus) { _, newValue in
            if newValue != .requested {
                selectedReceipts.removeAll()
            }
            // Clear all filters on tab switch — different context, fresh start.
            // Filters persist within a single tab across data refreshes.
            searchText = ""
            minAmount = nil
            maxAmount = nil
            Task { await viewModel.refresh(status: newValue) }
        }
    }

    // MARK: - Filter actions

    private func applyFilters() {
        viewModel.applyFilters(
            searchText: searchText,
            minAmount: minAmount,
            maxAmount: maxAmount
        )
    }

    private func clearAmountFilter() {
        minAmount = nil
        maxAmount = nil
        applyFilters()
    }

    // MARK: - Row actions

    private func toggleSelection(_ receipt: ReceiptItem) {
        if selectedReceipts.contains(receipt.id) {
            selectedReceipts.remove(receipt.id)
        } else {
            selectedReceipts.insert(receipt.id)
        }
    }

    private func printSingleRow(_ receipt: ReceiptItem) {
        viewModel.selectedReceipt = receipt
        showingPrintSheet = true
    }

    private func markRowAsPrinted(_ receipt: ReceiptItem) {
        Task {
            await viewModel.markAsPrinted(receipt)
            statusChangeTrigger += 1
        }
    }

    private func markRowAsRequested(_ receipt: ReceiptItem) {
        Task {
            await viewModel.markAsRequested(receipt)
            statusChangeTrigger += 1
        }
    }

    private func markRowAsNotRequested(_ receipt: ReceiptItem) {
        Task {
            await viewModel.markAsNotRequested(receipt)
            statusChangeTrigger += 1
        }
    }

    private func prepareRevertBatch(_ group: PrintBatchGroup) {
        batchPendingRevert = group
        showingRevertBatchConfirm = true
    }

    private func confirmRevertBatch() {
        guard let group = batchPendingRevert else { return }
        Task {
            await viewModel.revertBatch(group)
            batchPendingRevert = nil
            alertMessage = "Reverted \(group.receipts.count) receipt(s) to Requested."
            showingAlert = true
        }
    }

    // MARK: - Print actions

    private func handleTestPrint() {
        Task {
            let success = await service.printTestReceipt()
            alertMessage = success
                ? "Test receipt printed successfully"
                : "Test receipt printing cancelled or failed"
            showingAlert = true
        }
    }

    private func handlePrintAll() {
        totalReceiptsForPrint = viewModel.filteredReceipts.count
        showingPrintSheet = true
    }

    private func handleMarkSelectedPrinted() {
        let selection = viewModel.filteredReceipts.filter {
            selectedReceipts.contains($0.id)
        }
        guard !selection.isEmpty else { return }
        Task {
            await viewModel.markBatchAsPrinted(selection)
            selectedReceipts.removeAll()
        }
    }

    private func receiptsToPrint() -> [ReceiptItem] {
        if let single = viewModel.selectedReceipt {
            return [single]
        }
        if !selectedReceipts.isEmpty {
            return viewModel.filteredReceipts.filter { selectedReceipts.contains($0.id) }
        }
        return Array(viewModel.filteredReceipts.prefix(effectiveMaxReceipts))
    }

    private func handlePrintCompletion(_ outcome: PrintBatchOutcome) {
        let isBatchAll = viewModel.selectedReceipt == nil && selectedReceipts.isEmpty
        let remaining = totalReceiptsForPrint - effectiveMaxReceipts
        let hasRemainder = isBatchAll && totalReceiptsForPrint > effectiveMaxReceipts

        selectedReceipts.removeAll()
        viewModel.selectedReceipt = nil

        if outcome.wasCancelled {
            pendingPrintAlertMessage = "Print cancelled. No receipts were marked as printed."
        } else if outcome.failed == 0 {
            pendingPrintAlertMessage = hasRemainder
                ? "Successfully printed \(outcome.printed) receipt(s). \(remaining) more receipt(s) remaining."
                : "Successfully printed \(outcome.printed) receipt(s)"
        } else {
            pendingPrintAlertMessage = hasRemainder
                ? "Printed \(outcome.printed) receipt(s). Failed to print \(outcome.failed) receipt(s). \(remaining) more receipt(s) remaining."
                : "Printed \(outcome.printed) receipt(s). Failed to print \(outcome.failed) receipt(s)."
        }

        Task { await viewModel.refresh(status: selectedStatus) }
    }

    private func presentPendingAlertIfNeeded() {
        if let message = pendingPrintAlertMessage {
            alertMessage = message
            showingAlert = true
            pendingPrintAlertMessage = nil
        }
    }

    // MARK: - Bulk update

    private func handleBulkUpdate(amount: Double) {
        Task {
            bulkUpdateCount = await viewModel.bulkPromoteToRequested(
                minAmount: amount,
                fromStatus: selectedStatus
            )
            showingBulkUpdateAlert = true
            await viewModel.refresh(status: selectedStatus)
        }
    }

    private var bulkUpdateMessage: String {
        if bulkUpdateCount > 0 {
            return "Updated \(bulkUpdateCount) donation(s) to Requested status. They are now ready for printing."
        }
        return "No donations found matching the criteria."
    }
}

#Preview("Receipt Management") {
    NavigationStack {
        ReceiptManagementView()
    }
}
