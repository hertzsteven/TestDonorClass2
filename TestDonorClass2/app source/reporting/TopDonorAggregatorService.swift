//
//  TopDonorAggregatorService.swift
//  TestDonorClass2
//

import Foundation

/// Pure, testable service that groups donations by donor and applies
/// "important donor" filter criteria. It has no UI or repository
/// dependencies so it can be unit-tested with simple in-memory fixtures.
struct TopDonorAggregatorService {

    /// Builds aggregated `TopDonorSummary` rows from raw donations.
    /// - Parameters:
    ///   - donations: All donations to consider (already loaded from the DB).
    ///   - donorNames: Resolved display name per donor id.
    ///   - campaignNames: Resolved campaign name per campaign id.
    ///   - criteria: User-selected filter / sort criteria.
    func aggregate(
        donations: [Donation],
        donorNames: [Int: String],
        campaignNames: [Int: String],
        criteria: TopDonorFilterCriteria
    ) -> [TopDonorSummary] {

        let calendar = Calendar.current
        var filtered = donations

        // Date range (only when custom range is enabled).
        if criteria.useCustomDateRange {
            if let from = criteria.fromDate {
                let start = calendar.startOfDay(for: from)
                filtered = filtered.filter { $0.donationDate >= start }
            }
            if let to = criteria.toDate {
                let end = calendar.date(
                    bySettingHour: 23, minute: 59, second: 59, of: to
                ) ?? to
                filtered = filtered.filter { $0.donationDate <= end }
            }
        }

        // Campaign filter.
        if let campaignId = criteria.campaignId {
            filtered = filtered.filter { $0.campaignId == campaignId }
        }

        // Group by donorId (skip anonymous / donor-less donations — they
        // can't be aggregated meaningfully across "top donors").
        let grouped = Dictionary(grouping: filtered) { $0.donorId }

        var summaries: [TopDonorSummary] = []
        summaries.reserveCapacity(grouped.count)

        for (donorIdOptional, donorDonations) in grouped {
            guard let donorId = donorIdOptional else { continue }

            let total = donorDonations.reduce(0.0) { $0 + $1.amount }
            let count = donorDonations.count
            let avg = count > 0 ? total / Double(count) : 0
            let latest = donorDonations.map(\.donationDate).max() ?? .distantPast

            // Apply min-count threshold.
            guard count >= criteria.minDonationCount else { continue }
            // Apply min-total threshold.
            if let minTotal = criteria.minTotalAmount, total < minTotal {
                continue
            }

            let displayName = donorNames[donorId] ?? "Unknown Donor"

            let lines = donorDonations
                .sorted { $0.donationDate > $1.donationDate }
                .compactMap { donation -> TopDonorDonationLine? in
                    guard let did = donation.id else { return nil }
                    let campaign = donation.campaignId.flatMap { campaignNames[$0] }
                        ?? "General Support"
                    return TopDonorDonationLine(
                        donationId: did,
                        amount: donation.amount,
                        donationDate: donation.donationDate,
                        campaignName: campaign
                    )
                }

            summaries.append(
                TopDonorSummary(
                    donorId: donorId,
                    donorName: displayName,
                    totalAmount: total,
                    donationCount: count,
                    averageAmount: avg,
                    latestDonationDate: latest,
                    donations: lines
                )
            )
        }

        return sort(summaries, by: criteria.sortOption)
    }

    private func sort(
        _ summaries: [TopDonorSummary],
        by option: TopDonorSortOption
    ) -> [TopDonorSummary] {
        switch option {
        case .totalDescending:
            return summaries.sorted { $0.totalAmount > $1.totalAmount }
        case .countDescending:
            return summaries.sorted {
                if $0.donationCount != $1.donationCount {
                    return $0.donationCount > $1.donationCount
                }
                return $0.totalAmount > $1.totalAmount
            }
        case .mostRecent:
            return summaries.sorted { $0.latestDonationDate > $1.latestDonationDate }
        }
    }
}
