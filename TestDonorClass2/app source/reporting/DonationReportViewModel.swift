//
//  DonationReportViewModel.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 3/30/25.
//

import SwiftUI
import Combine // Using Combine for efficient updates

@MainActor
class DonationReportViewModel: ObservableObject {

    // --- Repositories ---
    private let donationRepository: DonationRepository
    private let donorRepository: DonorRepository
    private let campaignRepository: CampaignRepository

    // --- Filter State ---
    @Published var selectedTimeFrame: TimeFrame = .allTime
    @Published var selectedCampaignId: Int? = nil // Use ID, nil means "All"
    @Published var selectedDonorId: Int? = nil    // Use ID, nil means "All"
    @Published var minAmountString: String = ""
    @Published var maxAmountString: String = ""

    // --- Data for Pickers/Display ---
    @Published var availableCampaigns: [Campaign] = []
    @Published var selectedDonorName: String = "All" // Display name for the selected donor

    // --- Results ---
    @Published var filteredReportItems: [DonationReportItem] = []
    @Published var totalFilteredAmount: Double = 0
    @Published var averageFilteredAmount: Double = 0
    @Published var filteredCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isFilteringInProgress: Bool = false

    // --- Internal Cache (for name lookups) ---
    private var donorCache: [Int: String] = [:] // [DonorID: DonorName]
    private var campaignCache: [Int: String] = [:] // [CampaignID: CampaignName]
    private var allFetchedDonations: [Donation] = [] // Cache for in-memory filtering

    // --- Combine ---
    private var cancellables = Set<AnyCancellable>()

    init(
        donationRepository: DonationRepository = DonationRepository(),
        donorRepository: DonorRepository = DonorRepository(),
        campaignRepository: CampaignRepository = CampaignRepository()
    ) {
        self.donationRepository = donationRepository
        self.donorRepository = donorRepository
        self.campaignRepository = campaignRepository

        // Load campaigns for the picker initially
        loadSupportingData()

        // Combine pipeline to react to filter changes
        Publishers.CombineLatest4(
            $selectedTimeFrame,
            $selectedCampaignId,
            $selectedDonorId,
            Publishers.CombineLatest($minAmountString, $maxAmountString)
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main) // Debounce to avoid rapid updates
        .sink { [weak self] _ in
            self?.updateReport()
        }
        .store(in: &cancellables)

        // Initial report load
        updateReport()
    }

    // --- Data Loading ---
    func loadSupportingData() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                // Fetch Campaigns for Picker
                let campaigns = try await campaignRepository.getAll().sorted { $0.name < $1.name }
                self.availableCampaigns = campaigns
                self.campaignCache = Dictionary(uniqueKeysWithValues: campaigns.compactMap { $0.id != nil ? ($0.id!, $0.name) : nil })

                // Fetch Donors for Name Cache (Needed for report items)
                // NOTE: In a real app with thousands of donors, fetch *only needed* donors based on filtered donations.
                let donors = try await donorRepository.getAll()
                self.donorCache = Dictionary(uniqueKeysWithValues: donors.compactMap {
                    guard let id = $0.id else { return nil }
                    let name = $0.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? ($0.company ?? "Unknown") : $0.fullName
                    return (id, name)
                })

                // Fetch All Donations (For in-memory filtering in this example)
                // *** SCALABILITY NOTE: ***
                // Fetching ALL donations is INEFFICIENT for large datasets.
                // In production, filtering (WHERE clauses) should happen directly in the
                // DonationRepository using SQL based on the selected filters.
                self.allFetchedDonations = try await donationRepository.getAll()

                isLoading = false
                updateReport() // Trigger report update after loading supporting data

            } catch {
                errorMessage = "Error loading supporting data: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    // --- Report Update Logic ---
    func updateReport() {
        Task {
            defer { self.isFilteringInProgress = false }
            self.isFilteringInProgress = true
            
            // Simulate a small delay to prevent flickering for very fast operations
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // --- Apply Filters (In-Memory) ---
            // *** SCALABILITY NOTE: This filtering should be done in SQL in production ***
            var results = allFetchedDonations

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

            // 2. Filter by Campaign
            if let campaignId = selectedCampaignId {
                results = results.filter { $0.campaignId == campaignId }
            }

            // 3. Filter by Donor
            if let donorId = selectedDonorId {
                results = results.filter { $0.donorId == donorId }
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
            }
        }
    }

     // Called when donor is selected from DonorSearchView
     func donorSelected(_ donor: Donor?) {
         if let donor = donor {
             self.selectedDonorId = donor.id
             self.selectedDonorName = donor.fullName.isEmpty ? (donor.company ?? "Selected Donor") : donor.fullName
         } else {
             // Handle "All" selection
             self.selectedDonorId = nil
             self.selectedDonorName = "All"
         }
          // Manually trigger update if needed (Combine might handle it)
         // updateReport()
     }

    // --- Formatters ---
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}
