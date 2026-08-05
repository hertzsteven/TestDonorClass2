//
//  DonorDateRangeFilter.swift
//  TestDonorClass2
//

import Foundation

/// A date-range filter that resolves presets and custom ranges against
/// calendar-day boundaries.
struct DonorDateRangeFilter: Equatable {
    var preset: DonorDatePreset = .anyTime
    var customFrom: Date?
    var customTo: Date?

    /// Inclusive start / exclusive end interval in the given calendar.
    /// Returns `nil` when the filter should match any date.
    func resolvedInterval(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> DateInterval? {
        switch preset {
        case .anyTime:
            return nil

        case .today, .last2Days, .last7Days, .last30Days:
            guard let dayCount = preset.dayCount else { return nil }
            let startOfToday = calendar.startOfDay(for: now)
            guard let start = calendar.date(
                byAdding: .day,
                value: -(dayCount - 1),
                to: startOfToday
            ),
            let end = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
                return nil
            }
            return DateInterval(start: start, end: end)

        case .custom:
            guard let from = customFrom, let to = customTo else { return nil }
            let start = calendar.startOfDay(for: from)
            let endOfToDay = calendar.startOfDay(for: to)
            guard let end = calendar.date(byAdding: .day, value: 1, to: endOfToDay) else {
                return nil
            }
            // If the user picks to-before-from, still produce a valid interval.
            if end <= start {
                return DateInterval(start: start, end: calendar.date(byAdding: .day, value: 1, to: start) ?? start)
            }
            return DateInterval(start: start, end: end)
        }
    }
}
