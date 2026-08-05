//
//  ExternalDonationImportService.swift
//  TestDonorClass2
//
//  Classifies external-donation rows into triage buckets and applies the
//  decided writes. Preview never writes; apply re-validates before writing.
//

import Foundation

struct ExternalDonationImportService {
    private let donorRepository: any DonorSpecificRepositoryProtocol
    private let donationRepository: any DonationSpecificRepositoryProtocol
    private let importRepository: any ExternalDonationImportRepositoryProtocol
    private let matchService: DonorMatchService
    private let holdingDonorService: HoldingDonorService
    private let calendar: Calendar

    init(
        donorRepository: any DonorSpecificRepositoryProtocol,
        donationRepository: any DonationSpecificRepositoryProtocol,
        importRepository: any ExternalDonationImportRepositoryProtocol,
        matchService: DonorMatchService = DonorMatchService(),
        holdingDonorService: HoldingDonorService? = nil,
        calendar: Calendar = .current
    ) {
        self.donorRepository = donorRepository
        self.donationRepository = donationRepository
        self.importRepository = importRepository
        self.matchService = matchService
        self.holdingDonorService = holdingDonorService
            ?? HoldingDonorService(repository: donorRepository)
        self.calendar = calendar
    }

    init() throws {
        let donorRepository = try DonorRepository()
        let donationRepository = try DonationRepository()
        self.init(
            donorRepository: donorRepository,
            donationRepository: donationRepository,
            importRepository: ExternalDonationImportRepository(),
            holdingDonorService: HoldingDonorService(repository: donorRepository)
        )
    }

    // MARK: - Preview

    /// Classify every row. Writes nothing.
    func buildPreview(for records: [ExternalDonationRecord]) async throws -> [ExternalDonationItem] {
        let donors = try await donorRepository.getAll()
        let donations = try await donationRepository.getAll()
        let existingKeys = try await donationRepository.existingTransactionNumbers(
            records.map(\.importKey)
        )

        let donorsFund = HoldingDonorService.find(in: donors, kind: .donorsFund)
        let anonymous = HoldingDonorService.find(in: donors, kind: .anonymous)

        let duplicateIndex = Self.duplicateIndex(from: donations, calendar: calendar)

        return records.map { record in
            Self.item(
                for: record,
                donors: donors,
                existingKeys: existingKeys,
                duplicateIndex: duplicateIndex,
                donorsFund: donorsFund,
                anonymous: anonymous,
                matchService: matchService,
                calendar: calendar
            )
        }
    }

    // MARK: - Apply

    /// Writes decided rows in one transaction, then returns the write summary.
    func apply(
        _ items: [ExternalDonationItem],
        campaignId: Int?
    ) async throws -> ExternalDonationApplyResult {
        let ready = items.filter { $0.decision.isReady && $0.decision.willWrite }
        let skippedCount = items.filter {
            $0.decision.isReady && !$0.decision.willWrite
        }.count

        guard !ready.isEmpty else {
            return ExternalDonationApplyResult(
                donorsCreated: 0,
                donationsCreated: 0,
                skippedCount: skippedCount,
                revalidationFailureCount: 0
            )
        }

        let liveDonors = try await donorRepository.getAll()
        let liveKeys = try await donationRepository.existingTransactionNumbers(
            ready.map(\.record.importKey)
        )

        // Only create holding donors when a decided row actually needs them.
        var anonymousDonorId: Int?
        if ready.contains(where: { $0.decision == .anonymous }) {
            anonymousDonorId = try await holdingDonorService.donor(for: .anonymous).id
        }

        var actions: [ExternalDonationImportAction] = []
        var revalidationFailures = 0

        for item in ready {
            if liveKeys.contains(item.record.importKey) {
                revalidationFailures += 1
                continue
            }

            switch item.decision {
            case .attach(let donorId):
                guard liveDonors.contains(where: { $0.id == donorId }) else {
                    revalidationFailures += 1
                    continue
                }
                actions.append(
                    .createDonation(
                        Self.donation(
                            from: item.record,
                            donorId: donorId,
                            campaignId: campaignId,
                            isAnonymous: false
                        )
                    )
                )

            case .createNew:
                let donor = Self.newDonor(from: item.record)
                let donation = Self.donation(
                    from: item.record,
                    donorId: nil,
                    campaignId: campaignId,
                    isAnonymous: false
                )
                actions.append(.createDonorAndDonation(donor, donation))

            case .anonymous:
                guard let anonymousDonorId else {
                    revalidationFailures += 1
                    continue
                }
                actions.append(
                    .createDonation(
                        Self.donation(
                            from: item.record,
                            donorId: anonymousDonorId,
                            campaignId: campaignId,
                            isAnonymous: true
                        )
                    )
                )

            case .pending, .skip:
                continue
            }
        }

        var result = try await importRepository.apply(actions)
        result = ExternalDonationApplyResult(
            donorsCreated: result.donorsCreated,
            donationsCreated: result.donationsCreated,
            skippedCount: skippedCount,
            revalidationFailureCount: revalidationFailures
        )
        return result
    }

    // MARK: - Classification

    private static func item(
        for record: ExternalDonationRecord,
        donors: [Donor],
        existingKeys: Set<String>,
        duplicateIndex: Set<DuplicateKey>,
        donorsFund: Donor?,
        anonymous: Donor?,
        matchService: DonorMatchService,
        calendar: Calendar
    ) -> ExternalDonationItem {
        if existingKeys.contains(record.importKey) {
            return ExternalDonationItem(
                record: record,
                outcome: .alreadyImported,
                candidates: [],
                decision: .skip
            )
        }

        // Donors Fund always attaches to the holding organization.
        if record.source.usesHoldingOrganizationDonor {
            var candidates: [DonorCandidate] = []
            if let donorsFund, let id = donorsFund.id {
                candidates = [
                    DonorCandidate(
                        donor: donorsFund,
                        reason: .holdingOrganization,
                        rank: 1
                    )
                ]

                if isDuplicate(
                    donorId: id,
                    date: record.date,
                    amount: record.amount,
                    index: duplicateIndex,
                    calendar: calendar
                ) {
                    return ExternalDonationItem(
                        record: record,
                        outcome: .suspectedDuplicate,
                        candidates: candidates,
                        decision: .skip
                    )
                }

                let outcome: ExternalDonationOutcome = record.hasReviewNeeded
                    ? .forcedReview
                    : .likelyMatch
                let decision: ExternalDonationDecision = record.hasReviewNeeded
                    ? .pending
                    : .attach(donorId: id)
                return ExternalDonationItem(
                    record: record,
                    outcome: outcome,
                    candidates: candidates,
                    decision: decision
                )
            }

            // Holding donor not created yet — treat as new org donor named The Donors Fund.
            return ExternalDonationItem(
                record: record,
                outcome: record.hasReviewNeeded ? .forcedReview : .newDonor,
                candidates: [],
                decision: record.hasReviewNeeded ? .pending : .createNew
            )
        }

        if !record.hasUsableIdentity {
            var candidates: [DonorCandidate] = []
            if let anonymous {
                candidates = [
                    DonorCandidate(
                        donor: anonymous,
                        reason: .holdingOrganization,
                        rank: 1
                    )
                ]
            }
            return ExternalDonationItem(
                record: record,
                outcome: .unidentified,
                candidates: candidates,
                decision: .anonymous
            )
        }

        let candidates = matchService.candidates(for: record, among: donors)

        if record.hasReviewNeeded {
            return ExternalDonationItem(
                record: record,
                outcome: .forcedReview,
                candidates: candidates,
                decision: .pending
            )
        }

        if candidates.isEmpty {
            return ExternalDonationItem(
                record: record,
                outcome: .newDonor,
                candidates: [],
                decision: .createNew
            )
        }

        if candidates.count == 1, let only = candidates.first, let donorId = only.donor.id {
            if isDuplicate(
                donorId: donorId,
                date: record.date,
                amount: record.amount,
                index: duplicateIndex,
                calendar: calendar
            ) {
                return ExternalDonationItem(
                    record: record,
                    outcome: .suspectedDuplicate,
                    candidates: candidates,
                    decision: .skip
                )
            }

            return ExternalDonationItem(
                record: record,
                outcome: .likelyMatch,
                candidates: candidates,
                decision: .pending
            )
        }

        return ExternalDonationItem(
            record: record,
            outcome: .needsChoice,
            candidates: candidates,
            decision: .pending
        )
    }

    // MARK: - Models

    static func newDonor(from record: ExternalDonationRecord) -> Donor {
        // Donors Fund rows without a holding donor yet become the org record.
        if record.source.usesHoldingOrganizationDonor {
            return Donor(
                company: HoldingDonorKind.donorsFund.companyName,
                address: record.address.street,
                addl_line: record.address.additionalLine,
                suite: record.address.suite,
                city: record.address.city,
                state: record.address.state,
                zip: record.address.zip,
                email: record.email,
                phone: record.phone,
                donorSource: record.source.donorSource.rawValue,
                notes: combinedNotes(from: record)
            )
        }

        return Donor(
            company: record.organizationName,
            firstName: record.firstName,
            lastName: record.lastName,
            jewishName: record.hebrewName,
            address: record.address.street,
            addl_line: record.address.additionalLine,
            suite: record.address.suite,
            city: record.address.city,
            state: record.address.state,
            zip: record.address.zip,
            email: record.email,
            phone: record.phone,
            donorSource: record.source.donorSource.rawValue,
            notes: combinedNotes(from: record)
        )
    }

    static func donation(
        from record: ExternalDonationRecord,
        donorId: Int?,
        campaignId: Int?,
        isAnonymous: Bool
    ) -> Donation {
        Donation(
            donorId: donorId,
            campaignId: campaignId,
            amount: record.amount,
            donationType: record.source.donationType,
            paymentStatus: .completed,
            transactionNumber: record.importKey,
            requestEmailReceipt: false,
            requestPrintedReceipt: false,
            notes: combinedNotes(from: record),
            isAnonymous: isAnonymous,
            donationDate: record.date
        )
    }

    private static func combinedNotes(from record: ExternalDonationRecord) -> String? {
        var parts: [String] = []
        parts.append("Imported from \(record.source.displayName)")
        if let reference = record.referenceNumber {
            parts.append("Ref: \(reference)")
        }
        if let memo = record.memo { parts.append(memo) }
        if let details = record.details { parts.append(details) }
        if let product = record.product { parts.append("Product: \(product)") }
        if let review = record.reviewNeeded { parts.append("Review: \(review)") }
        if let mother = record.mothersHebrewName {
            parts.append("Mother's Hebrew name: \(mother)")
        }
        let joined = parts.joined(separator: " | ")
        return joined.isEmpty ? nil : joined
    }

    // MARK: - Duplicate detection

    private struct DuplicateKey: Hashable {
        let donorId: Int
        let day: Date
        let amountCents: Int
    }

    private static func duplicateIndex(
        from donations: [Donation],
        calendar: Calendar
    ) -> Set<DuplicateKey> {
        var index = Set<DuplicateKey>()
        for donation in donations {
            guard let donorId = donation.donorId else { continue }
            let day = calendar.startOfDay(for: donation.donationDate)
            let cents = Int((donation.amount * 100).rounded())
            index.insert(DuplicateKey(donorId: donorId, day: day, amountCents: cents))
        }
        return index
    }

    private static func isDuplicate(
        donorId: Int,
        date: Date,
        amount: Double,
        index: Set<DuplicateKey>,
        calendar: Calendar
    ) -> Bool {
        let key = DuplicateKey(
            donorId: donorId,
            day: calendar.startOfDay(for: date),
            amountCents: Int((amount * 100).rounded())
        )
        return index.contains(key)
    }
}
