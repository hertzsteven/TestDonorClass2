//
//  DonorFilterCriteria.swift
//  TestDonorClass2
//

import Foundation

/// User-selected filter criteria for the Donors report.
struct DonorFilterCriteria: Equatable {
    var addedRange = DonorDateRangeFilter()
    var updatedRange = DonorDateRangeFilter()
    var emailPresence: DonorFieldPresence = .any
    var addressPresence: DonorFieldPresence = .any
    var sortOption: DonorReportSortOption = .nameAscending

    static let `default` = DonorFilterCriteria()
}
