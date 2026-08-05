//
//  DonorReportSortOption.swift
//  TestDonorClass2
//

import Foundation

/// Sort order for the Donors report.
enum DonorReportSortOption: String, CaseIterable, Identifiable {
    case nameAscending = "Name (A-Z)"
    case newestAdded = "Newest Added"
    case recentlyUpdated = "Recently Updated"

    var id: String { rawValue }
}
