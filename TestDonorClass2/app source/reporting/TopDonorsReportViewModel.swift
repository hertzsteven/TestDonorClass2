//
//  TopDonorsReportViewModel.swift
//  TestDonorClass2
//

import Foundation
import Observation

/// Coordinates UI state for the Top Donors report. Delegates all
/// aggregation logic to `TopDonorAggregatorService` and uses repositories
/// only to fetch the raw input data.
@MainActor
@Observable
final class TopDonorsReportViewModel {

    // MARK: - User-driven state

    var criteria: TopDonorFilterCriteria = .default {
        didSet { scheduleRecompute() }
    }

    // MARK: - Outputs

    private(set) var summaries: [TopDonorSummary] = []
    private(set) var availableCampaigns: [Campaign] = []
    private(set) var isLoading: Bool = false
    private(set) var isRecomputing: Bool = false
    private(set) var errorMessage: String?

    // MARK: - Derived summary metrics

    var matchingDonorCount: Int { summaries.count }
    var matchingTotalAmount: Double {
        summaries.reduce(0.0) { $0 + $1.totalAmount }
    }
    var matchingDonationCount: Int {
        summaries.reduce(0) { $0 + $1.donationCount }
    }

    // MARK: - Dependencies

    @ObservationIgnored private let donationRepository: DonationRepository
    @ObservationIgnored private let donorRepository: DonorRepository
    @ObservationIgnored private let campaignRepository: CampaignRepository
    @ObservationIgnored private let aggregator: TopDonorAggregatorService

    // MARK: - Caches

    @ObservationIgnored private var allDonations: [Donation] = []
    @ObservationIgnored private var donorNames: [Int: String] = [:]
    @ObservationIgnored private var campaignNames: [Int: String] = [:]

    @ObservationIgnored private var debounceTask: Task<Void, Never>?

    // MARK: - Init

    init(
        donationRepository: DonationRepository,
        donorRepository: DonorRepository,
        campaignRepository: CampaignRepository,
        aggregator: TopDonorAggregatorService = TopDonorAggregatorService()
    ) {
        self.donationRepository = donationRepository
        self.donorRepository = donorRepository
        self.campaignRepository = campaignRepository
        self.aggregator = aggregator
    }

    // MARK: - Loading

    func loadInitialData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let campaignsTask = campaignRepository.getAll()
            async let donorsTask = donorRepository.getAll()
            async let donationsTask = donationRepository.getAll()

            let campaigns = try await campaignsTask
                .sorted { $0.name < $1.name }
            let donors = try await donorsTask
            let donations = try await donationsTask

            availableCampaigns = campaigns
            campaignNames = Dictionary(uniqueKeysWithValues: campaigns.compactMap { campaign in
                guard let id = campaign.id else { return nil }
                return (id, campaign.name)
            })
            donorNames = Dictionary(uniqueKeysWithValues: donors.compactMap { donor in
                guard let id = donor.id else { return nil }
                let trimmed = donor.fullName
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let name = trimmed.isEmpty ? (donor.company ?? "Unknown") : trimmed
                return (id, name)
            })
            allDonations = donations

            recompute()
            isLoading = false
        } catch {
            errorMessage = "Error loading data: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Recomputation

    private func scheduleRecompute() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            if Task.isCancelled { return }
            self?.recomputeWithIndicator()
        }
    }

    private func recomputeWithIndicator() {
        isRecomputing = true
        recompute()
        isRecomputing = false
    }

    private func recompute() {
        summaries = aggregator.aggregate(
            donations: allDonations,
            donorNames: donorNames,
            campaignNames: campaignNames,
            criteria: criteria
        )
    }

    // MARK: - Filter helpers

    func resetFilters() {
        criteria = .default
    }
}
