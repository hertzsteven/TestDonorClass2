//
//  DonorsReportViewModel.swift
//  TestDonorClass2
//

import Foundation
import Observation

/// Coordinates UI state for the Donors report. Delegates filtering and sorting
/// to `DonorReportFilterService` and uses the repository only to fetch donors.
@MainActor
@Observable
final class DonorsReportViewModel {

    // MARK: - User-driven state

    var criteria: DonorFilterCriteria = .default {
        didSet { scheduleRecompute() }
    }

    var selectedDonorID: Int?

    // MARK: - Outputs

    /// Filtered results. Kept as a writable `var` so the detail pane can bind
    /// into an element the same way `DonorDetailContainer` does.
    var donors: [Donor] = []
    private(set) var isLoading: Bool = false
    private(set) var isRecomputing: Bool = false
    private(set) var errorMessage: String?

    // MARK: - Derived summary metrics

    var matchingDonorCount: Int { donors.count }

    var matchingWithEmailCount: Int {
        donors.reduce(0) { count, donor in
            count + (hasNonEmptyText(donor.email) ? 1 : 0)
        }
    }

    var matchingWithAddressCount: Int {
        donors.reduce(0) { count, donor in
            count + (donor.currentAddress.isEmpty ? 0 : 1)
        }
    }

    // MARK: - Dependencies

    @ObservationIgnored private let donorRepository: DonorRepository
    @ObservationIgnored private let filterService: DonorReportFilterService

    // MARK: - Caches

    @ObservationIgnored private var allDonors: [Donor] = []
    @ObservationIgnored private var debounceTask: Task<Void, Never>?

    // MARK: - Init

    init(
        donorRepository: DonorRepository,
        filterService: DonorReportFilterService = DonorReportFilterService()
    ) {
        self.donorRepository = donorRepository
        self.filterService = filterService
    }

    // MARK: - Loading

    func loadInitialData() async {
        isLoading = true
        errorMessage = nil

        do {
            allDonors = try await donorRepository.getAll()
            recompute()
            isLoading = false
        } catch {
            errorMessage = "Error loading donors: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func refresh() async {
        await loadInitialData()
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
        donors = filterService.filter(
            donors: allDonors,
            criteria: criteria
        )

        if let selectedDonorID,
           !donors.contains(where: { $0.id == selectedDonorID }) {
            self.selectedDonorID = nil
        }
    }

    // MARK: - Filter helpers

    func resetFilters() {
        criteria = .default
    }

    private func hasNonEmptyText(_ value: String?) -> Bool {
        guard let value else { return false }
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
