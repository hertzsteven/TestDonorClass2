//
//  TopDonorFilterCriteria.swift
//  TestDonorClass2
//

import Foundation

/// User-selected filter criteria for the Top Donors report.
struct TopDonorFilterCriteria: Equatable {
    var minTotalAmount: Double?
    var minDonationCount: Int = 1
    var useCustomDateRange: Bool = false
    var fromDate: Date?
    var toDate: Date?
    var campaignId: Int?
    var sortOption: TopDonorSortOption = .totalDescending

    static let `default` = TopDonorFilterCriteria()
}
