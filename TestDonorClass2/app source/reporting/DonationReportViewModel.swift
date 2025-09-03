import SwiftUI

@MainActor
class DonationReportViewModel: ObservableObject {
    // MARK: – Dependencies
    private let donationRepository: DonationRepository
    private let donorRepository:    DonorRepository
    private let campaignRepository: CampaignRepository

    // MARK: – Debounce Helper
    private var debounceTask: Task<Void,Never>?

    private func scheduleFilter() {
        // cancel any pending filter update
        debounceTask?.cancel()
        // schedule a new one 400 ms out
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            await self?.updateReport()
        }
    }

    // MARK: – Filter State
    @Published var selectedTimeFrame: TimeFrame = .allTime {
        didSet { scheduleFilter() }
    }
    @Published var selectedCampaignId: Int? = nil {
        didSet { scheduleFilter() }
    }
    @Published var selectedDonorId: Int? = nil {
        didSet { scheduleFilter() }
    }
    @Published var minAmountString: String = "" {
        didSet { scheduleFilter() }
    }
    @Published var maxAmountString: String = "" {
        didSet { scheduleFilter() }
    }
    @Published var showOnlyPrayerNotes: Bool = false {
        didSet { scheduleFilter() }
    }
    
    // Add custom date range properties
    @Published var fromDate: Date? = nil {
        didSet { scheduleFilter() }
    }
    @Published var toDate: Date? = nil {
        didSet { scheduleFilter() }
    }
    @Published var useCustomDateRange: Bool = false {
        didSet {
            if useCustomDateRange {
                let today = Date()
                if fromDate == nil { fromDate = today }
                if toDate == nil { toDate = today }
            }
            scheduleFilter()
        }
    }
    
    @Published var exportText: String?

    // MARK: – Picker / UI Data
    @Published var availableCampaigns: [Campaign] = []
    @Published var selectedDonorName:  String     = "All"

    // MARK: – Loading & Error State
    @Published var isLoading: Bool             = false
    @Published var isFilteringInProgress: Bool = false
    @Published var errorMessage: String?

    // MARK: – Results & Aggregates
    @Published var filteredReportItems: [DonationReportItem] = []
    @Published var totalFilteredAmount:   Double             = 0
    @Published var averageFilteredAmount: Double             = 0
    @Published var filteredCount:         Int                = 0

    // MARK: – Internal Caches
    private var donorCache: [Int:String]       = [:]
    private var campaignCache: [Int:String]    = [:]
    private var allFetchedDonations: [Donation] = []

    // MARK: – Init
    init(
        donationRepository: DonationRepository,
        donorRepository:    DonorRepository,
        campaignRepository: CampaignRepository
    ) {
        self.donationRepository = donationRepository
        self.donorRepository   = donorRepository
        self.campaignRepository = campaignRepository

        isLoading = true
        loadSupportingData()
    }

    // MARK: – Load Supporting Data
    func loadSupportingData() {
        Task {
            await MainActor.run {
                isLoading    = true
                errorMessage = nil
            }

            do {
                async let campaigns = campaignRepository.getAll().sorted { $0.name < $1.name }
                async let donors    = donorRepository.getAll()
                async let donations = donationRepository.getAll()

                let fetchedCampaigns = try await campaigns
                let fetchedDonors    = try await donors
                let fetchedDonations = try await donations

                await MainActor.run {
                    availableCampaigns = fetchedCampaigns
                    campaignCache = Dictionary(
                        uniqueKeysWithValues: fetchedCampaigns.compactMap { c in
                            guard let id = c.id else { return nil }
                            return (id, c.name)
                        }
                    )
                    donorCache = Dictionary(
                        uniqueKeysWithValues: fetchedDonors.compactMap { d in
                            guard let id = d.id else { return nil }
                            let name = d.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty ? (d.company ?? "Unknown") : d.fullName
                            return (id, name)
                        }
                    )
                    allFetchedDonations = fetchedDonations
                }

                // initial report
                await updateReport()

                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error loading supporting data: \(error.localizedDescription)"
                    isLoading    = false
                }
            }
        }
    }

    // MARK: – Report Generation
    func updateReport() async {
        await MainActor.run {
            if !isLoading {
                isFilteringInProgress = true
            }
            errorMessage = nil
        }

        // small delay to prevent flicker
        try? await Task.sleep(nanoseconds: 150_000_000)

        let now = Date()
        let cal = Calendar.current
        var results = allFetchedDonations

        // 1. Time-frame filter
        if useCustomDateRange {
            if let from = fromDate {
                let startOfFromDate = cal.startOfDay(for: from)
                results = results.filter { $0.donationDate >= startOfFromDate }
            }
            if let to = toDate {
                let endOfToDate = cal.date(bySettingHour: 23, minute: 59, second: 59, of: to) ?? to
                results = results.filter { $0.donationDate <= endOfToDate }
            }
        } else {
            // Use preset time frames
            switch selectedTimeFrame {
            case .last7Days:
                if let start = cal.date(byAdding: .day, value: -7, to: now) {
                    results = results.filter { $0.donationDate >= start && $0.donationDate <= now }
                }
            case .last30Days:
                if let start = cal.date(byAdding: .day, value: -30, to: now) {
                    results = results.filter { $0.donationDate >= start && $0.donationDate <= now }
                }
            case .last90Days:
                if let start = cal.date(byAdding: .day, value: -90, to: now) {
                    results = results.filter { $0.donationDate >= start && $0.donationDate <= now }
                }
            case .allTime:
                break
            }
        }

        // 2. Campaign
        if let cid = selectedCampaignId {
            results = results.filter { $0.campaignId == cid }
        }
        // 3. Donor
        if let did = selectedDonorId {
            results = results.filter { $0.donorId == did }
        }
        // 4. Amount range
        if let min = Double(minAmountString) {
            results = results.filter { $0.amount >= min }
        }
        if let max = Double(maxAmountString) {
            results = results.filter { $0.amount <= max }
        }
        // 5. Prayer-notes only
        if showOnlyPrayerNotes {
            results = results.filter { $0.notes != nil }
        }
        
        // if useCustomDateRange {
        //     if let fromDate = fromDate, let toDate = toDate {
        //         results = results.filter { $0.donationDate >= fromDate && $0.donationDate <= toDate }
        //     }
        // }

        // STEP-1: build items synchronously (no email yet)
        let items = results.compactMap { d -> DonationReportItem? in
            guard let id = d.id else { return nil }

            let donorName    = d.donorId.flatMap { donorCache[$0] }
                ?? (d.isAnonymous ? "Anonymous" : "Unknown Donor")
            let campaignName = d.campaignId.flatMap { campaignCache[$0] }
                ?? "General Support"

            return DonationReportItem(
                id: id,
                donorId: d.donorId,
                donorName: donorName,
                campaignName: campaignName,
                amount: d.amount,
                donationDate: d.donationDate,
                hasPrayerNote: d.notes != nil,
                prayerNote: d.notes,
                email: nil
            )
        }

        // STEP-2: asynchronously look up donor emails
        var itemsWithEmail: [DonationReportItem] = []
        
        do {
            for item in items {
                // Check if task was cancelled before making database call
                try Task.checkCancellation()
                
                if let did = item.donorId {
                    do {
                        let donor = try await donorRepository.getOne(did)
                        // rebuild with email
                        itemsWithEmail.append(
                            DonationReportItem(
                                id: item.id,
                                donorId: item.donorId,
                                donorName: item.donorName,
                                campaignName: item.campaignName,
                                amount: item.amount,
                                donationDate: item.donationDate,
                                hasPrayerNote: item.hasPrayerNote,
                                prayerNote: item.prayerNote,
                                email: donor?.email
                            )
                        )
                    } catch is CancellationError {
                        // Task was cancelled - stop processing and return early
                        return
                    } catch {
                        // Other errors (like database issues) should still be logged
                        print("Error fetching donor \(did): \(error)")
                        // Add item without email
                        itemsWithEmail.append(item)
                    }
                } else {
                    itemsWithEmail.append(item)
                }
            }
        } catch is CancellationError {
            // Task was cancelled during the loop - return early without updating UI
            return
        } catch {
            // Handle any other unexpected errors from Task.checkCancellation()
            print("Unexpected error during donor email fetching: \(error)")
            // Continue with items without emails
            itemsWithEmail = items
        }

        await MainActor.run {
            filteredReportItems   = itemsWithEmail.sorted { $0.donationDate > $1.donationDate }
            filteredCount         = filteredReportItems.count
            totalFilteredAmount   = filteredReportItems.reduce(0) { $0 + $1.amount }
            averageFilteredAmount = filteredCount > 0
                ? totalFilteredAmount / Double(filteredCount)
                : 0
            isFilteringInProgress = false
        }
    }

    // MARK: – Donor Selection
    func donorSelected(_ donor: Donor?) {
        if let donor = donor, let id = donor.id {
            selectedDonorId   = id
            selectedDonorName = donor.fullName.isEmpty
                ? (donor.company ?? "Selected Donor")
                : donor.fullName
        } else {
            selectedDonorId   = nil
            selectedDonorName = "All"
        }
    }

    func getDonation(_ id: Int) async throws -> Donation? {
        return try await donationRepository.getOne(id)
    }

    // MARK: – Single Donation Update
    func updateSingleDonation(_ donationId: Int) async {
        do {
            // Get the fresh donation from database
            guard let updatedDonation = try await donationRepository.getOne(donationId) else {
                print("❌ Could not find donation with ID: \(donationId)")
                return
            }
            
            await MainActor.run {
                // Update the cached donation in allFetchedDonations
                if let index = allFetchedDonations.firstIndex(where: { $0.id == donationId }) {
                    allFetchedDonations[index] = updatedDonation
                }
                
                // Update the display item in filteredReportItems
                if let displayIndex = filteredReportItems.firstIndex(where: { $0.id == donationId }) {
                    let oldItem = filteredReportItems[displayIndex]
                    
                    // Create updated report item
                    let donorName = updatedDonation.donorId.flatMap { donorCache[$0] }
                        ?? (updatedDonation.isAnonymous ? "Anonymous" : "Unknown Donor")
                    let campaignName = updatedDonation.campaignId.flatMap { campaignCache[$0] }
                        ?? "General Support"
                    
                    let updatedItem = DonationReportItem(
                        id: donationId,
                        donorId: updatedDonation.donorId,
                        donorName: donorName,
                        campaignName: campaignName,
                        amount: updatedDonation.amount,
                        donationDate: updatedDonation.donationDate,
                        hasPrayerNote: updatedDonation.notes != nil,
                        prayerNote: updatedDonation.notes,
                        email: oldItem.email // Keep the existing email to avoid extra DB call
                    )
                    
                    filteredReportItems[displayIndex] = updatedItem
                    
                    // Recalculate totals
                    filteredCount = filteredReportItems.count
                    totalFilteredAmount = filteredReportItems.reduce(0) { $0 + $1.amount }
                    averageFilteredAmount = filteredCount > 0 
                        ? totalFilteredAmount / Double(filteredCount) 
                        : 0
                    
                    print("✅ Updated single donation: \(updatedDonation.amount)")
                }
            }
        } catch {
            print("💥 Error updating single donation: \(error)")
        }
    }

    // MARK: – CSV Export
    func generateExportText() async throws -> String {
        let header = [
            "Donor ID","Salutation","First Name","Last Name","Company",
            "Jewish Name","Address","Additional Line","Suite","City","State",
            "ZIP","Email","Phone","Donor Source","Donor Notes",
            "Donation Amount","Donation Date","Campaign","Donation Notes"
        ].joined(separator: ",") + "\n"

        var csv = header
        for item in filteredReportItems {
            if let did = item.donorId,
               let donor = try await donorRepository.getOne(did)
            {
                let fields = [
                    String(did),
                    escapeCsvField(donor.salutation),
                    escapeCsvField(donor.firstName),
                    escapeCsvField(donor.lastName),
                    escapeCsvField(donor.company),
                    escapeCsvField(donor.jewishName),
                    escapeCsvField(donor.address),
                    escapeCsvField(donor.addl_line),
                    escapeCsvField(donor.suite),
                    escapeCsvField(donor.city),
                    escapeCsvField(donor.state),
                    escapeCsvField(donor.zip),
                    escapeCsvField(donor.email),
                    escapeCsvField(donor.phone),
                    escapeCsvField(donor.donorSource),
                    escapeCsvField(donor.notes),
                    Self.currencyFormatter.string(for: item.amount) ?? "0.00",
                    Self.dateFormatter.string(from: item.donationDate),
                    escapeCsvField(item.campaignName),
                    escapeCsvField(item.prayerNote)
                ]
                csv += fields.joined(separator: ",") + "\n"
            }
        }
        return csv
    }

    private func escapeCsvField(_ value: String?) -> String {
        guard let v = value else { return "" }
        if v.contains(",") || v.contains("\"") || v.contains("\n") {
            let esc = v.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(esc)\""
        }
        return v
    }

    // MARK: – Formatters
    static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        return f
    }()
    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle  = .short
        f.timeStyle  = .none
        return f
    }()
}