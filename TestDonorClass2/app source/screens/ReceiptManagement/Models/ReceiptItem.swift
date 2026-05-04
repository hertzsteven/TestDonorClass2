//
//  ReceiptItem.swift
//  TestDonorClass2
//
//  Display-layer value type for a single receipt row in the
//  Receipt Management screen. Decoupled from the persistence
//  `Donation` model so the UI can be tested in isolation.
//

import Foundation

struct ReceiptItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let donationId: Int
    let donorName: String
    let amount: Double
    let date: Date
    let campaignName: String?
    let status: ReceiptStatus
}
