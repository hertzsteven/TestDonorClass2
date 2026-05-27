//
//  PrintBatchGroup.swift
//  TestDonorClass2
//
//  Display grouping for receipts printed in the same batch.
//

import Foundation

struct PrintBatchGroup: Identifiable, Sendable {
    /// Present for batched receipts; `nil` for the unbatched section.
    let batch: PrintBatch?
    let receipts: [ReceiptItem]

    var id: String {
        if let batchId = batch?.id {
            return "batch-\(batchId)"
        }
        return "unbatched"
    }

    var isUnbatched: Bool { batch == nil }

    var sectionTitle: String {
        guard let batch else {
            return "Unbatched (\(receipts.count))"
        }
        let dateText = batch.printedAt.formatted(date: .abbreviated, time: .shortened)
        return "\(dateText) · \(receipts.count) receipt\(receipts.count == 1 ? "" : "s")"
    }

    /// Whether the Printed tab should show batch sections instead of a flat list.
    static func shouldGroup(
        status: ReceiptStatus,
        searchText: String,
        minAmount: Double?,
        maxAmount: Double?
    ) -> Bool {
        status == .printed
            && searchText.isEmpty
            && minAmount == nil
            && maxAmount == nil
    }

    /// Builds batch sections from printed receipts, newest batches first.
    static func buildGroups(from receipts: [ReceiptItem]) -> [PrintBatchGroup] {
        let batchedReceipts = receipts.filter { $0.printBatchId != nil }
        let unbatchedReceipts = receipts.filter { $0.printBatchId == nil }

        let groupedByBatch = Dictionary(grouping: batchedReceipts) { $0.printBatchId! }

        var groups: [PrintBatchGroup] = groupedByBatch.map { batchId, items in
            let printedAt = items.compactMap(\.printedAt).max() ?? items.map(\.date).max() ?? Date()
            let batch = PrintBatch(
                id: batchId,
                printedAt: printedAt,
                receiptCount: items.count,
                label: nil,
                status: .printed
            )
            let sortedItems = items.sorted { $0.donorName.localizedStandardCompare($1.donorName) == .orderedAscending }
            return PrintBatchGroup(batch: batch, receipts: sortedItems)
        }
        .sorted { lhs, rhs in
            (lhs.batch?.printedAt ?? .distantPast) > (rhs.batch?.printedAt ?? .distantPast)
        }

        if !unbatchedReceipts.isEmpty {
            let sortedUnbatched = unbatchedReceipts.sorted {
                $0.donorName.localizedStandardCompare($1.donorName) == .orderedAscending
            }
            groups.append(PrintBatchGroup(batch: nil, receipts: sortedUnbatched))
        }

        return groups
    }
}
