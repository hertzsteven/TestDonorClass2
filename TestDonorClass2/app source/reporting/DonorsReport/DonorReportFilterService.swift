//
//  DonorReportFilterService.swift
//  TestDonorClass2
//

import Foundation

/// Pure filter and sort logic for the Donors report. No repository or UI
/// dependencies so it can be unit-tested with plain donor fixtures.
struct DonorReportFilterService {

    func filter(
        donors: [Donor],
        criteria: DonorFilterCriteria,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [Donor] {
        let addedInterval = criteria.addedRange.resolvedInterval(now: now, calendar: calendar)
        let updatedInterval = criteria.updatedRange.resolvedInterval(now: now, calendar: calendar)

        let filtered = donors.filter { donor in
            matchesDate(donor.createdAt, interval: addedInterval)
                && matchesDate(donor.updatedAt, interval: updatedInterval)
                && matchesPresence(
                    hasValue: hasNonEmptyText(donor.email),
                    requirement: criteria.emailPresence
                )
                && matchesPresence(
                    hasValue: !donor.currentAddress.isEmpty,
                    requirement: criteria.addressPresence
                )
        }

        return sort(filtered, by: criteria.sortOption)
    }

    // MARK: - Predicates

    private func matchesDate(_ date: Date, interval: DateInterval?) -> Bool {
        guard let interval else { return true }
        return date >= interval.start && date < interval.end
    }

    private func matchesPresence(hasValue: Bool, requirement: DonorFieldPresence) -> Bool {
        switch requirement {
        case .any:
            return true
        case .present:
            return hasValue
        case .missing:
            return !hasValue
        }
    }

    private func hasNonEmptyText(_ value: String?) -> Bool {
        guard let value else { return false }
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Sorting

    private func sort(_ donors: [Donor], by option: DonorReportSortOption) -> [Donor] {
        switch option {
        case .nameAscending:
            return donors.sorted { lhs, rhs in
                let left = sortName(for: lhs)
                let right = sortName(for: rhs)
                if left != right {
                    return left.localizedStandardCompare(right) == .orderedAscending
                }
                return (lhs.id ?? 0) < (rhs.id ?? 0)
            }

        case .newestAdded:
            return donors.sorted { lhs, rhs in
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt > rhs.createdAt
                }
                return (lhs.id ?? 0) < (rhs.id ?? 0)
            }

        case .recentlyUpdated:
            return donors.sorted { lhs, rhs in
                if lhs.updatedAt != rhs.updatedAt {
                    return lhs.updatedAt > rhs.updatedAt
                }
                return (lhs.id ?? 0) < (rhs.id ?? 0)
            }
        }
    }

    private func sortName(for donor: Donor) -> String {
        let last = donor.lastName?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let first = donor.firstName?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let company = donor.company?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !last.isEmpty || !first.isEmpty {
            return "\(last) \(first)".trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if !company.isEmpty {
            return company
        }
        return "Unknown"
    }
}
