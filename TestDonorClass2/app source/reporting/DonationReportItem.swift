//
//  DonationReportItem.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 3/30/25.
//


import Foundation

// Represents a single row in the donation report list
struct DonationReportItem: Identifiable, Hashable {
    let id: Int // Donation ID
    let donorName: String
    let campaignName: String
    let amount: Double
    let donationDate: Date
    let hasPrayerNote: Bool
    let prayerNote: String?
}

// Re-use TimeFrame enum if not already accessible globally
enum TimeFrame: String, CaseIterable, Identifiable {
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case last90Days = "Last 90 Days"
    case allTime = "All Time"

    var id: String { self.rawValue }
}
