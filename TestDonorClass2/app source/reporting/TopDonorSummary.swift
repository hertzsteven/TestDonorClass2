//
//  TopDonorSummary.swift
//  TestDonorClass2
//

import Foundation

/// Aggregated giving information for a single donor, displayed as one row
/// in the Top Donors report.
struct TopDonorSummary: Identifiable, Equatable {
    let donorId: Int
    let donorName: String
    let totalAmount: Double
    let donationCount: Int
    let averageAmount: Double
    let latestDonationDate: Date
    let donations: [TopDonorDonationLine]

    var id: Int { donorId }
}

/// A single donation line shown when a `TopDonorSummary` is expanded.
struct TopDonorDonationLine: Identifiable, Equatable {
    let donationId: Int
    let amount: Double
    let donationDate: Date
    let campaignName: String

    var id: Int { donationId }
}
