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
    let selectedReceipts: Set<UUID>
    let status: ReceiptStatus

    let onToggleSelection: (ReceiptItem) -> Void
    let onPrintRow: (ReceiptItem) -> Void
    let onMarkPrinted: (ReceiptItem) -> Void
    let onMarkRequested: (ReceiptItem) -> Void

    var body: some View {
        List {
            Section(header: Text("Receipts")) {
                ForEach(receipts) { receipt in
                    ReceiptRowView(
                        receipt: receipt,
                        isSelected: selectedReceipts.contains(receipt.id),
                        showCheckbox: status == .requested
                    )
                    .contentShape(.rect)
                    .onTapGesture {
                        guard status == .requested else { return }
                        onToggleSelection(receipt)
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
                        if receipt.status == .printed {
                            Button("Mark Requested") { onMarkRequested(receipt) }
                                .tint(.orange)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
