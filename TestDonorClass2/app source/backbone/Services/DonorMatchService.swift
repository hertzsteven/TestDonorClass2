//
//  DonorMatchService.swift
//  TestDonorClass2
//
//  Pure ranking of donor candidates for an external-donation row. No database
//  access — callers pass the donor list in.
//

import Foundation

struct DonorMatchService {

    /// Maximum candidates returned for a needs-choice row.
    private let maxCandidates: Int

    init(maxCandidates: Int = 12) {
        self.maxCandidates = maxCandidates
    }

    /// Ranked candidates for one CSV row. Empty when nothing plausible matches.
    func candidates(
        for record: ExternalDonationRecord,
        among donors: [Donor]
    ) -> [DonorCandidate] {
        var scored: [DonorCandidate] = []

        let recordFirst = normalizedName(record.firstName)
        let recordLast = normalizedName(record.lastName)
        let recordOrg = normalizedName(record.organizationName)
        let hasAddress = !record.address.isEmpty

        for donor in donors {
            guard donor.id != nil else { continue }

            let donorFirst = normalizedName(donor.firstName)
            let donorLast = normalizedName(donor.lastName)
            let donorCompany = normalizedName(donor.company)

            var reason: DonorMatchReason?
            var rank = 100

            if !recordFirst.isEmpty,
               !recordLast.isEmpty,
               recordFirst == donorFirst,
               recordLast == donorLast {
                reason = .exactName
                rank = 10
            } else if !recordOrg.isEmpty,
                      recordOrg == donorCompany {
                reason = .organizationName
                rank = 20
            } else if !recordLast.isEmpty,
                      recordLast == donorLast {
                reason = .lastNameOnly
                rank = 40
            }

            guard let matchedReason = reason else { continue }

            if hasAddress, donor.currentAddress.matches(record.address) {
                scored.append(
                    DonorCandidate(
                        donor: donor,
                        reason: .addressTieBreak,
                        rank: max(1, rank - 5)
                    )
                )
            } else {
                scored.append(
                    DonorCandidate(
                        donor: donor,
                        reason: matchedReason,
                        rank: rank
                    )
                )
            }
        }

        return scored
            .sorted { lhs, rhs in
                if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
                return (lhs.donor.id ?? 0) < (rhs.donor.id ?? 0)
            }
            .prefix(maxCandidates)
            .map { $0 }
    }

    private func normalizedName(_ value: String?) -> String {
        PostalAddressNormalizer.normalized(value)
    }
}
