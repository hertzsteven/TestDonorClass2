// Contents of ./reporting/DonationReportViewModel.swift
//
//  DonationReportViewModel.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 3/30/25.
//

import SwiftUI
import Combine // Using Combine for efficient updates

@MainActor // Ensures @Published properties are updated on the main thread
class DonationReportViewModel: ObservableObject {

    // --- Repositories ---
    // Made private, injected via init
    private let donationRepository: DonationRepository
    private let donorRepository: DonorRepository
    private let campaignRepository: CampaignRepository

    // --- Filter State (@Published for UI binding) ---
    @Published var selectedTimeFrame: TimeFrame = .allTime
    @Published var selectedCampaignId: Int? = nil // Use ID, nil means "All"
    @Published var selectedDonorId: Int? = nil    // Use ID, nil means "All"
    @Published var minAmountString: String = ""
    @Published var maxAmountString: String = ""

    // --- Data for Pickers/Display (@Published for UI binding) ---
    @Published var availableCampaigns: [Campaign] = []
    @Published var selectedDonorName: String = "All" // Display name for the selected donor

    // --- Results (@Published for UI binding) ---
    @Published var filteredReportItems: [DonationReportItem] = []
    @Published var totalFilteredAmount: Double = 0
    @Published var averageFilteredAmount: Double = 0
    @Published var filteredCount: Int = 0

    // --- UI State (@Published for UI binding) ---
    @Published var isLoading: Bool = false // For initial data load
    @Published var errorMessage: String? = nil
    @Published var isFilteringInProgress: Bool = false // For updates triggered by filters

    // --- Internal Cache (for name lookups and in-memory filtering) ---
    private var donorCache: [Int: String] = [:] // [DonorID: DonorName]
    private var campaignCache: [Int: String] = [:] // [CampaignID: CampaignName]
    private var allFetchedDonations: [Donation] = [] // Cache for in-memory filtering

    // --- Combine ---
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    // Dependencies are now required, no default arguments
    init(
        donationRepository: DonationRepository,
        donorRepository: DonorRepository,
        campaignRepository: CampaignRepository
    ) {
        self.donationRepository = donationRepository
        self.donorRepository = donorRepository
        self.campaignRepository = campaignRepository

        print("DonationReportViewModel: Initializing...")

        // 1. Load supporting data (campaigns, donor cache, INITIAL donations)
        // This now also triggers the first updateReport upon completion.
        loadSupportingData()

        // 2. Setup Combine pipeline to react to filter changes
        // This pipeline will call updateReport() automatically when filters change (debounced).
        Publishers.CombineLatest4(
            $selectedTimeFrame,
            $selectedCampaignId,
            $selectedDonorId,
            Publishers.CombineLatest($minAmountString.map { Double($0) }, $maxAmountString.map { Double($0) }) // Combine amounts directly
                 // Also listen to changes in the source data if it could change elsewhere
                 // Publishers.Merge(..., $allFetchedDonations.dropFirst()) // Example if needed
        )
        .debounce(for: .milliseconds(400), scheduler: RunLoop.main) // Debounce filter changes
        .sink { [weak self] _ in
            // Trigger filtering when any filter changes
             print("DonationReportViewModel: Combine Sink triggered update.")
            // Use Task to call the async function from the sync Combine sink
            Task {
                await self?.updateReport()
            }
        }
        .store(in: &cancellables)

        // 3. Initial report calculation is handled by loadSupportingData completion
        print("DonationReportViewModel: Init complete.")
    }

    // MARK: - Data Loading
    func loadSupportingData() {
        // Run asynchronous loading logic within a Task
        Task {
            print("DonationReportViewModel: Starting loadSupportingData...")
            // Set loading state ON the main thread
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
                print("DonationReportViewModel: isLoading set to true.")
            }

            do {
                // Fetch supporting data concurrently where possible
                async let campaigns = campaignRepository.getAll().sorted { $0.name < $1.name }
                async let donors = donorRepository.getAll()
                // Fetch ALL donations ONCE for initial caching
                async let initialDonations = donationRepository.getAll()

                // Await results
                let fetchedCampaigns = try await campaigns
                let fetchedDonors = try await donors
                let fetchedInitialDonations = try await initialDonations
                print("DonationReportViewModel: Fetched \(fetchedCampaigns.count) campaigns, \(fetchedDonors.count) donors, \(fetchedInitialDonations.count) initial donations.")


                // Process and store data ON the main thread
                await MainActor.run {
                    self.availableCampaigns = fetchedCampaigns
                    self.campaignCache = Dictionary(uniqueKeysWithValues: fetchedCampaigns.compactMap { $0.id != nil ? ($0.id!, $0.name) : nil })

                    self.donorCache = Dictionary(uniqueKeysWithValues: fetchedDonors.compactMap {
                        guard let id = $0.id else { return nil }
                        let name = $0.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? ($0.company ?? "Unknown") : $0.fullName
                        return (id, name)
                    })

                    // Store the initially fetched donations in the cache
                    self.allFetchedDonations = fetchedInitialDonations
                    print("DonationReportViewModel: Caches populated.")
                }

                // Trigger the first report update AFTER data is loaded and caches are ready
                 print("DonationReportViewModel: Calling updateReport after successful load.")
                await updateReport()

                // Set loading state OFF on the main thread after successful load and first update
                await MainActor.run {
                    self.isLoading = false
                     print("DonationReportViewModel: isLoading set to false.")
                }
                print("DonationReportViewModel: loadSupportingData finished successfully.")

            } catch {
                print("DonationReportViewModel: Error loading supporting data: \(error)")
                // Set error message and loading state OFF on the main thread
                await MainActor.run {
                    self.errorMessage = "Error loading supporting data: \(error.localizedDescription)"
                    self.isLoading = false
                     print("DonationReportViewModel: Error occurred, isLoading set to false.")
                }
            }
        }
    }

    // MARK: - Report Update Logic
    // Make this function async since filtering might be slow or become async later
    func updateReport() async {
         print("DonationReportViewModel: Starting updateReport...")
        // Set filtering state ON the main thread
        await MainActor.run {
            // Only show filtering indicator if not already initial loading
            if !self.isLoading {
                 print("DonationReportViewModel: Setting isFilteringInProgress to true.")
                self.isFilteringInProgress = true
            }
             self.errorMessage = nil // Clear previous errors on new filter
        }

        // Simulate network/computation delay ONLY if filtering, not during initial load.
        // Add a small delay even for fast operations to avoid UI flickering
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds


        // --- Apply Filters (In-Memory on the cached data) ---
        // *** SCALABILITY NOTE: This filtering should ideally be done in SQL ***
        var results = self.allFetchedDonations // Start with the cached full list
         print("DonationReportViewModel: Filtering \(results.count) cached donations...")

        // 1. Filter by Time Frame
        let now = Date()
        let calendar = Calendar.current
        switch selectedTimeFrame {
            case .last7Days:
                if let startDate = calendar.date(byAdding: .day, value: -7, to: now) {
                    results = results.filter { $0.donationDate >= startDate && $0.donationDate <= now }
                }
            case .last30Days:
                if let startDate = calendar.date(byAdding: .day, value: -30, to: now) {
                    results = results.filter { $0.donationDate >= startDate && $0.donationDate <= now }
                }
            case .last90Days:
                 if let startDate = calendar.date(byAdding: .day, value: -90, to: now) {
                     results = results.filter { $0.donationDate >= startDate && $0.donationDate <= now }
                 }
            case .allTime:
                break // No time filter needed
        }
         print("DonationReportViewModel: After time filter: \(results.count) donations.")

        // 2. Filter by Campaign
        if let campaignId = selectedCampaignId {
            results = results.filter { $0.campaignId == campaignId }
             print("DonationReportViewModel: After campaign filter (\(campaignId)): \(results.count) donations.")
        }

        // 3. Filter by Donor
        if let donorId = selectedDonorId {
            results = results.filter { $0.donorId == donorId }
             print("DonationReportViewModel: After donor filter (\(donorId)): \(results.count) donations.")
        }

        // 4. Filter by Amount
        let minAmount = Double(minAmountString)
        let maxAmount = Double(maxAmountString)

        if let min = minAmount {
            results = results.filter { $0.amount >= min }
        }
        if let max = maxAmount {
            results = results.filter { $0.amount <= max }
        }
        if minAmount != nil || maxAmount != nil {
             print("DonationReportViewModel: After amount filter (min: \(minAmountString), max: \(maxAmountString)): \(results.count) donations.")
        }
        // --- End In-Memory Filtering ---


        // --- Map to Report Items ---
        let reportItems = results.compactMap { donation -> DonationReportItem? in
            guard let donationId = donation.id else { return nil } // Should always have an ID from DB

            // Lookup names from cache
            let donorName = donation.donorId.flatMap { donorCache[$0] } ?? (donation.isAnonymous ? "Anonymous" : "Unknown Donor")
            let campaignName = donation.campaignId.flatMap { campaignCache[$0] } ?? "General Support"

            return DonationReportItem(
                id: donationId,
                donorName: donorName,
                campaignName: campaignName,
                amount: donation.amount,
                donationDate: donation.donationDate
            )
        }
         print("DonationReportViewModel: Mapped to \(reportItems.count) report items.")

        // Update Published properties on the Main Thread
        await MainActor.run {
            self.filteredReportItems = reportItems.sorted { $0.donationDate > $1.donationDate } // Sort newest first

            // --- Calculate Aggregates ---
            self.totalFilteredAmount = self.filteredReportItems.reduce(0) { $0 + $1.amount }
            self.filteredCount = self.filteredReportItems.count
            if self.filteredCount > 0 {
                self.averageFilteredAmount = self.totalFilteredAmount / Double(self.filteredCount)
            } else {
                self.averageFilteredAmount = 0
            }
             print("DonationReportViewModel: Aggregates calculated (Count: \(self.filteredCount), Total: \(self.totalFilteredAmount)).")

            // Turn off filtering indicator
             print("DonationReportViewModel: Setting isFilteringInProgress to false.")
            self.isFilteringInProgress = false
        }
         print("DonationReportViewModel: updateReport finished.")
    }

     // MARK: - Actions
     // Called when donor is selected from DonorSearchSelectionView
     func donorSelected(_ donor: Donor?) {
          print("DonationReportViewModel: Donor selected: \(donor?.fullName ?? "All")")
         if let donor = donor, let donorId = donor.id {
             self.selectedDonorId = donorId // This change triggers the Combine pipeline
             self.selectedDonorName = donor.fullName.isEmpty ? (donor.company ?? "Selected Donor") : donor.fullName
         } else {
             // Handle "All" selection or nil donor
             self.selectedDonorId = nil // This change triggers the Combine pipeline
             self.selectedDonorName = "All"
         }
         // No need to manually call updateReport() here, Combine pipeline handles it.
     }

    // MARK: - Formatters (Static for efficiency)
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        // Consider setting locale: formatter.locale = Locale.current
        return formatter
    }()

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        // Consider setting locale: formatter.locale = Locale.current
        return formatter
    }()
}
