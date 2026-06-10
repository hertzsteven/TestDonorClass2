//
//  ReceiptContentView.swift
//  TestDonorClass2
//
//  Picks between loading, empty, and list+action-bar content for the
//  Receipts screen. Pure presentation — all callbacks are passed in.
//

import SwiftUI

struct ReceiptContentView: View {
    let isLoading: Bool
    let receipts: [ReceiptItem]
    let printedBatchGroups: [PrintBatchGroup]
    let isGroupingByBatch: Bool
    let selectedReceipts: Set<UUID>
    let status: ReceiptStatus
    let hasActiveFilter: Bool
    let effectiveMaxReceipts: Int

    let onToggleSelection: (ReceiptItem) -> Void
    let onPrintRow: (ReceiptItem) -> Void
    let onMarkPrinted: (ReceiptItem) -> Void
    let onMarkRequested: (ReceiptItem) -> Void
    let onRevertBatch: (PrintBatchGroup) -> Void
    let onViewDetails: (ReceiptItem) -> Void

    let onDeselectAll: () -> Void
    let onTestPrint: () -> Void
    let onRefresh: () -> Void
    let onChangeMax: (Int) -> Void
    let onPrintAll: () -> Void
    let onMarkSelectedPrinted: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Loading receipts...")
                    .padding()
                Spacer()
            } else if receipts.isEmpty {
                EmptyReceiptsView(
                    status: status,
                    hasActiveFilter: hasActiveFilter
                )
            } else {
                ReceiptListView(
                    receipts: receipts,
                    printedBatchGroups: printedBatchGroups,
                    isGroupingByBatch: isGroupingByBatch,
                    selectedReceipts: selectedReceipts,
                    status: status,
                    onToggleSelection: onToggleSelection,
                    onPrintRow: onPrintRow,
                    onMarkPrinted: onMarkPrinted,
                    onMarkRequested: onMarkRequested,
                    onRevertBatch: onRevertBatch,
                    onViewDetails: onViewDetails
                )
            }

            if !isLoading {
                ReceiptActionBarView(
                    status: status,
                    hasItems: !receipts.isEmpty,
                    selectedCount: selectedReceipts.count,
                    maxReceiptsPerPrint: effectiveMaxReceipts,
                    onDeselectAll: onDeselectAll,
                    onTestPrint: onTestPrint,
                    onRefresh: onRefresh,
                    onChangeMax: onChangeMax,
                    onPrintAll: onPrintAll,
                    onMarkSelectedPrinted: onMarkSelectedPrinted
                )
            }
        }
    }
}
