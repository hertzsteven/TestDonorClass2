//
//  DonorDatePreset.swift
//  TestDonorClass2
//

import Foundation

/// Calendar-day presets for donor date-range filters.
enum DonorDatePreset: String, CaseIterable, Identifiable {
    case anyTime = "Any Time"
    case today = "Today"
    case last2Days = "Last 2 Days"
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case custom = "Custom Range"

    var id: String { rawValue }

    /// Number of calendar days in the preset window, counting today as day one.
    /// Returns `nil` for `.anyTime` and `.custom`.
    var dayCount: Int? {
        switch self {
        case .anyTime, .custom:
            return nil
        case .today:
            return 1
        case .last2Days:
            return 2
        case .last7Days:
            return 7
        case .last30Days:
            return 30
        }
    }
}
