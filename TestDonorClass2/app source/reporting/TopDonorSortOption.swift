//
//  TopDonorSortOption.swift
//  TestDonorClass2
//

import Foundation

/// Sort order for the Top Donors report.
enum TopDonorSortOption: String, CaseIterable, Identifiable {
    case totalDescending = "Highest Total"
    case countDescending = "Most Frequent"
    case mostRecent = "Most Recent"

    var id: String { rawValue }
}
