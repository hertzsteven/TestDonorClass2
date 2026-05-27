//
//  PrintBatchGroupTests.swift
//  TestDonorClass2Tests
//

import Foundation
import Testing
@testable import TestDonorClass2

struct PrintBatchGroupTests {

    @Test func shouldGroupOnlyOnPrintedTabWithoutFilters() {
        #expect(
            PrintBatchGroup.shouldGroup(
                status: .printed,
                searchText: "",
                minAmount: nil,
                maxAmount: nil
            )
        )
        #expect(
            !PrintBatchGroup.shouldGroup(
                status: .printed,
                searchText: "Smith",
                minAmount: nil,
                maxAmount: nil
            )
        )
        #expect(
            !PrintBatchGroup.shouldGroup(
                status: .printed,
                searchText: "",
                minAmount: 10,
                maxAmount: nil
            )
        )
        #expect(
            !PrintBatchGroup.shouldGroup(
                status: .requested,
                searchText: "",
                minAmount: nil,
                maxAmount: nil
            )
        )
    }

    @Test func buildGroupsSeparatesBatchesAndUnbatched() {
        let batchDate = Date(timeIntervalSince1970: 1_700_000_000)
        let receipts = [
            receipt(id: 1, batchId: 10, printedAt: batchDate),
            receipt(id: 2, batchId: 10, printedAt: batchDate),
            receipt(id: 3, batchId: 20, printedAt: batchDate.addingTimeInterval(60)),
            receipt(id: 4, batchId: nil, printedAt: nil),
        ]

        let groups = PrintBatchGroup.buildGroups(from: receipts)

        #expect(groups.count == 3)
        #expect(groups[0].batch?.id == 20)
        #expect(groups[1].batch?.id == 10)
        #expect(groups[2].isUnbatched)
        #expect(groups[2].receipts.count == 1)
    }

    private func receipt(id: Int, batchId: Int?, printedAt: Date?) -> ReceiptItem {
        ReceiptItem(
            donationId: id,
            donorName: "Donor \(id)",
            amount: 100,
            date: Date(),
            campaignName: nil,
            status: .printed,
            printBatchId: batchId,
            printedAt: printedAt
        )
    }
}
