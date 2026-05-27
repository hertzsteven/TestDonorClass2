//
//  PrintBatch.swift
//  TestDonorClass2
//
//  Represents a group of receipts printed together in one print job.
//

import Foundation
import GRDB

enum PrintBatchStatus: String, Codable, Sendable {
    case printed = "printed"
    case partiallyReverted = "partially_reverted"
    case fullyReverted = "fully_reverted"
}

struct PrintBatch: Identifiable, Codable, FetchableRecord, PersistableRecord, Hashable, Sendable {
    var id: Int?
    var printedAt: Date
    var receiptCount: Int
    var label: String?
    var status: PrintBatchStatus

    static let databaseTableName = "print_batch"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let printedAt = Column(CodingKeys.printedAt)
        static let receiptCount = Column(CodingKeys.receiptCount)
        static let label = Column(CodingKeys.label)
        static let status = Column(CodingKeys.status)
    }

    enum CodingKeys: String, CodingKey, ColumnExpression {
        case id
        case printedAt = "printed_at"
        case receiptCount = "receipt_count"
        case label
        case status
    }

    init(
        id: Int? = nil,
        printedAt: Date = Date(),
        receiptCount: Int,
        label: String? = nil,
        status: PrintBatchStatus = .printed
    ) {
        self.id = id
        self.printedAt = printedAt
        self.receiptCount = receiptCount
        self.label = label
        self.status = status
    }
}
