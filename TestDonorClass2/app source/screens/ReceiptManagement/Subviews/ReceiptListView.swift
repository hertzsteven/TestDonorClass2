//
//  ReceiptListView.swift
//  TestDonorClass2
//
//  The scrollable receipts list with swipe actions. Selection logic is
//  driven by the parent (only the Requested tab is selectable).
//

import SwiftUI

struct ReceiptListView: View {
    let receipts: [ReceiptItem]
    let printedBatchGroups: [PrintBatchGroup]
    let isGroupingByBatch: Bool
    let selectedReceipts: Set<UUID>
    let status: ReceiptStatus

    let onToggleSelection: (ReceiptItem) -> Void
    let onPrintRow: (ReceiptItem) -> Void
    let onMarkPrinted: (ReceiptItem) -> Void
    let onMarkRequested: (ReceiptItem) -> Void
    let onRevertBatch: (PrintBatchGroup) -> Void
    let onViewDetails: (ReceiptItem) -> Void

    var body: some View {
        List {
            if isGroupingByBatch {
                ForEach(printedBatchGroups) { group in
                    Section {
                        ForEach(group.receipts) { receipt in
                            receiptRow(receipt)
                        }
                    } header: {
                        PrintedBatchSectionHeader(group: group) {
                            onRevertBatch(group)
                        }
                    }
                }
            } else {
                Section(header: Text("Receipts")) {
                    ForEach(receipts) { receipt in
                        receiptRow(receipt, showBatchChip: status == .printed)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private func receiptRow(_ receipt: ReceiptItem, showBatchChip: Bool = false) -> some View {
        ReceiptRowView(
            receipt: receipt,
            isSelected: selectedReceipts.contains(receipt.id),
            showCheckbox: status == .requested,
            showBatchChip: showBatchChip
        )
        .contentShape(.rect)
        .onTapGesture {
            guard status == .requested else { return }
            onToggleSelection(receipt)
        }
        .contextMenu {
            Button("View Details", systemImage: "doc.text.magnifyingglass") {
                onViewDetails(receipt)
            }
        }
        .swipeActions {
            if receipt.status == .requested || receipt.status == .failed {
                Button("Print") { onPrintRow(receipt) }
                    .tint(.blue)
            }
            if receipt.status != .printed {
                Button("Mark Printed") { onMarkPrinted(receipt) }
                    .tint(.green)
            }
            if receipt.status == .printed || receipt.status == .notRequested || receipt.status == .digitallySent {
                Button("Mark Requested") { onMarkRequested(receipt) }
                    .tint(.orange)
            }
        }
    }
}
