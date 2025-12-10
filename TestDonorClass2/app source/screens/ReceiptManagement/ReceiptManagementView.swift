//
//  ReceiptManagementView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 3/5/25.
//

import SwiftUI

struct ReceiptManagementView: View {
    // MODIFY: Fix StateObject initialization
    @StateObject private var viewModel: ReceiptManagementViewModel
    @State private var showingPrintingSheet = false
    @State private var selectedStatus: ReceiptStatus = .requested
    @State private var searchText = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var totalReceiptsForPrint = 0
    @State private var selectedReceipts: Set<UUID> = []
    @State private var overrideMaxReceipts: Int? = nil
    @State private var bulkUpdateThreshold: String = "100"
    @State private var showingBulkUpdateAlert = false
    @State private var bulkUpdateCount = 0
    
    // Computed property for effective max receipts (override or Settings value)
    private var effectiveMaxReceipts: Int {
        overrideMaxReceipts ?? viewModel.maxReceiptsPerPrint
    }
    
    init() {
        let donationRepo = try! DonationRepository()
        _viewModel = StateObject(wrappedValue: ReceiptManagementViewModel(
            donationRepository: donationRepo
        ))
    }
    
    private func getReceiptsToPrint() -> [ReceiptItem] {
        if viewModel.selectedReceipt != nil {
            // Single receipt from swipe action
            return [viewModel.selectedReceipt!]
        } else if !selectedReceipts.isEmpty {
            // Selected receipts from multi-select
            return viewModel.filteredReceipts.filter { selectedReceipts.contains($0.id) }
        } else {
            // Print All (with limit)
            return Array(viewModel.filteredReceipts.prefix(effectiveMaxReceipts))
        }
    }
    
    private func createTestDonationInfo() -> DonationInfo {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: Date())
        
        return DonationInfo(
            donorName: "John Doe",
            donorTitle: "Mr.",
            donationAmount: 100.00,
            date: dateString,
            donorAddress: "123 Main Street",
            donorCity: "New York",
            donorState: "NY",
            donorZip: "10001",
            receiptNumber: "TEST-001"
        )
    }
    
    private func printTestReceipt() {
        let testDonation = createTestDonationInfo()
        let printingService = ReceiptPrintingService()
        
        printingService.printReceipt(for: testDonation) { success in
            DispatchQueue.main.async {
                if success {
                    alertMessage = "Test receipt printed successfully"
                } else {
                    alertMessage = "Test receipt printing cancelled or failed"
                }
                showingAlert = true
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Receipt Status Filter
            Picker("Filter", selection: $selectedStatus) {
                ForEach(ReceiptStatus.allCases, id: \.self) { status in
                    Text("\(status.displayName) (\(viewModel.statusCounts[status] ?? 0))").tag(status)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: selectedStatus) { _ in
                // Clear selections when switching away from requested tab
                if selectedStatus != .requested {
                    selectedReceipts.removeAll()
                }
                Task {
                    await viewModel.loadReceipts(status: selectedStatus)
                    await viewModel.loadAllStatusCounts()
                }
            }
            
            // Maximum Receipts Per Print Override Setting
            if selectedStatus == .requested {
                HStack {
                    Spacer()
                    Text("Max receipts per print:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(effectiveMaxReceipts)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(minWidth: 30)
                    Stepper("", value: Binding(
                        get: { effectiveMaxReceipts },
                        set: { overrideMaxReceipts = $0 }
                    ), in: 1...100)
                        .labelsHidden()
                        .fixedSize()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            // Bulk Update Section for Not Requested tab
            if selectedStatus == .notRequested {
                VStack(spacing: 8) {
                    HStack {
                        Text("Update donations ≥ $")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("Amount", text: $bulkUpdateThreshold)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        Text("to Requested")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            Task {
                                if let amount = Double(bulkUpdateThreshold) {
                                    bulkUpdateCount = await viewModel.bulkUpdateToRequested(minAmount: amount)
                                    showingBulkUpdateAlert = true
                                    // Refresh the current tab
                                    await viewModel.loadReceipts(status: selectedStatus)
                                }
                            }
                        }) {
                            Label("Update", systemImage: "arrow.right.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(Double(bulkUpdateThreshold) == nil)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search receipts", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: searchText) { _ in
                        viewModel.filterReceipts(searchText)
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.filterReceipts("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            
            // Receipt List
            if viewModel.isLoading {
                ProgressView("Loading receipts...")
                    .padding()
                Spacer()
            } else if viewModel.filteredReceipts.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "printer.filled.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("No receipts found")
                        .font(.headline)
                    
                    Text(searchText.isEmpty ?
                             "There are no \(selectedStatus.displayName.lowercased()) receipts" :
                             "No receipts match your search")
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            } else {
                List {
                    Section(header: Text("Receipts")) {
                        ForEach(viewModel.filteredReceipts) { receiptItem in
                            ReceiptRowView(
                                receipt: receiptItem,
                                isSelected: selectedReceipts.contains(receiptItem.id),
                                showCheckbox: selectedStatus == .requested
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Only allow selection on requested tab
                                guard selectedStatus == .requested else { return }
                                if selectedReceipts.contains(receiptItem.id) {
                                    selectedReceipts.remove(receiptItem.id)
                                } else {
                                    selectedReceipts.insert(receiptItem.id)
                                }
                            }
                            .swipeActions {
                                if receiptItem.status == .requested || receiptItem.status == .failed {
                                    Button("Print") {
                                        viewModel.selectedReceipt = receiptItem
                                        showingPrintingSheet = true
                                    }
                                    .tint(.blue)
                                }
                                
                                if receiptItem.status != .printed {
                                    Button("Mark Printed") {
                                        Task {
                                            await viewModel.markAsPrinted(receipt: receiptItem)
                                        }
                                    }
                                    .tint(.green)
                                }
                                
                                if receiptItem.status == .printed {
                                    Button("Mark Requested") {
                                        Task {
                                            await viewModel.markAsRequested(receipt: receiptItem)
                                            selectedStatus = .requested
                                        }
                                        
                                    }
                                    .tint(.orange)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                
                // Action Buttons
                HStack {
                    // Deselect All button (only appears on requested tab when there are selections)
                    if selectedStatus == .requested && !selectedReceipts.isEmpty {
                        Button(action: {
                            selectedReceipts.removeAll()
                        }) {
                            Label("Deselect All", systemImage: "xmark.circle")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    if selectedStatus == .requested {
                        Button(action: {
                            printTestReceipt()
                        }) {
                            Label("Test Print", systemImage: "checkmark.circle")
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.orange)
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.refreshReceipts()
                        }
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    
                    if !viewModel.filteredReceipts.isEmpty && selectedStatus == .requested {
                        Button(action: {
                            totalReceiptsForPrint = viewModel.filteredReceipts.count
                            showingPrintingSheet = true
                        }) {
                            if selectedReceipts.isEmpty {
                                Label("Print All", systemImage: "printer")
                                    .padding(.horizontal, 10)
                            } else {
                                Label("Print Selected (\(selectedReceipts.count))", systemImage: "printer")
                                    .padding(.horizontal, 10)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Receipts")
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Receipt Status"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Bulk Update Complete", isPresented: $showingBulkUpdateAlert) {
            Button("OK") {
                // Switch to Requested tab to see the updated donations
                if bulkUpdateCount > 0 {
                    selectedStatus = .requested
                }
            }
        } message: {
            if bulkUpdateCount > 0 {
                Text("Updated \(bulkUpdateCount) donation(s) to Requested status. They are now ready for printing.")
            } else {
                Text("No donations found matching the criteria.")
            }
        }
        .sheet(isPresented: $showingPrintingSheet) {
            PrintReceiptSheetView(
                receipts: getReceiptsToPrint(),
                onCompletion: { success, total, failed in
                    // Clear selections after printing
                    selectedReceipts.removeAll()
                    
                    showingAlert = true
                    if failed == 0 {
                        if viewModel.selectedReceipt == nil && selectedReceipts.isEmpty && totalReceiptsForPrint > effectiveMaxReceipts {
                            let remaining = totalReceiptsForPrint - effectiveMaxReceipts
                            alertMessage = "Successfully printed \(success) receipt(s). \(remaining) more receipt(s) remaining."
                        } else {
                            alertMessage = "Successfully printed \(success) receipt(s)"
                        }
                    } else {
                        if viewModel.selectedReceipt == nil && selectedReceipts.isEmpty && totalReceiptsForPrint > effectiveMaxReceipts {
                            let remaining = totalReceiptsForPrint - effectiveMaxReceipts
                            alertMessage = "Printed \(success) receipt(s). Failed to print \(failed) receipt(s). \(remaining) more receipt(s) remaining."
                        } else {
                            alertMessage = "Printed \(success) receipt(s). Failed to print \(failed) receipt(s)."
                        }
                    }
                    
                    Task {
                        await viewModel.refreshReceipts()
                        await viewModel.loadAllStatusCounts()
                    }
                }
            )
        }
        .onAppear {
            // Reset override to Settings value when returning to the screen
            overrideMaxReceipts = nil
            Task {
                await viewModel.loadReceipts(status: selectedStatus)
                await viewModel.loadAllStatusCounts()
            }
        }
    }
}

struct ReceiptRowView: View {
    let receipt: ReceiptItem
    let isSelected: Bool
    let showCheckbox: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox - only show when showCheckbox is true
            if showCheckbox {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(receipt.donorName)
                        .font(.headline)
                    Spacer()
                    Text(formattedAmount)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            
            HStack {
                Text(receipt.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                statusBadge
            }
            
            if let campaign = receipt.campaignName, !campaign.isEmpty {
                Text("Campaign: \(campaign)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
                Text("Donation ID: \(receipt.donationId)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: receipt.amount)) ?? "$\(receipt.amount)"
    }
    
    private var statusBadge: some View {
        Text(receipt.status.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch receipt.status {
        case .notRequested: return .gray
        case .requested: return .orange
        case .queued: return .blue
        case .printed: return .green
        case .failed: return .red
        }
    }
}

struct ReceiptItem: Identifiable {
    let id: UUID
    let donationId: Int
    let donorName: String
    let amount: Double
    let date: Date
    let campaignName: String?
    let status: ReceiptStatus
}

class ReceiptManagementViewModel: ObservableObject {
    @Published var allReceipts: [ReceiptItem] = []
    @Published var filteredReceipts: [ReceiptItem] = []
    @Published var isLoading = false
    @Published var selectedReceipt: ReceiptItem? = nil
    @Published var statusCounts: [ReceiptStatus: Int] = [:]
    
    var maxReceiptsPerPrint: Int {
        let value = UserDefaults.standard.integer(forKey: "maxReceiptsPerPrint")
        return value == 0 ? 10 : value
    }
    
    private let donationRepository: DonationRepository
    
    init(donationRepository: DonationRepository) { // Dependency must be injected
        self.donationRepository = donationRepository
        print("ReceiptManagementViewModel Initialized with repository.")
        
        // Observe UserDefaults changes for maxReceiptsPerPrint
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Trigger view update when UserDefaults changes
            self?.objectWillChange.send()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadReceipts(status: ReceiptStatus) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Load donations that have receipt requests with the specified status
            let donations = try await donationRepository.getReceiptRequests(status: status)
            
            // Convert donations to receipt items
            let receiptItems = try await convertDonationsToReceiptItems(donations)
            
            await MainActor.run {
                self.allReceipts = receiptItems
                self.filteredReceipts = receiptItems
                self.isLoading = false
            }
        } catch {
            print("Error loading receipts: \(error)")
            await MainActor.run {
                self.allReceipts = []
                self.filteredReceipts = []
                self.isLoading = false
            }
        }
    }
    
    private func convertDonationsToReceiptItems(_ donations: [Donation]) async throws -> [ReceiptItem] {
        var receiptItems: [ReceiptItem] = []
        
        for donation in donations {
            // Get donor name
            var donorName = "Anonymous"
            if let donorId = donation.donorId, !donation.isAnonymous {
                if let donor = try? await donationRepository.getDonorForDonation(donorId: donorId) {
                    donorName = "\(donor.firstName ?? "") \(donor.lastName ?? "")"
                    if donorName.trimmingCharacters(in: .whitespaces).isEmpty {
                        donorName = donor.company ?? "Unknown"
                    }
                }
            }
            
            // Get campaign name
            var campaignName: String? = nil
            if let campaignId = donation.campaignId {
                if let campaign = try? await donationRepository.getCampaignForDonation(campaignId: campaignId) {
                    campaignName = campaign.name
                }
            }
            
            // Create receipt item
            let receiptItem = ReceiptItem(
                id: UUID(),
                donationId: donation.id ?? 0,
                donorName: donorName,
                amount: donation.amount,
                date: donation.donationDate,
                campaignName: campaignName,
                status: donation.receiptStatus
            )
            
            receiptItems.append(receiptItem)
        }
        
        return receiptItems
    }
    
    func refreshReceipts() async {
        await loadReceipts(status: .requested)
        await loadAllStatusCounts()
    }
    
    func bulkUpdateToRequested(minAmount: Double) async -> Int {
        do {
            let count = try await donationRepository.bulkUpdateToRequested(minAmount: minAmount)
            await loadAllStatusCounts()
            return count
        } catch {
            print("Error in bulk update: \(error)")
            return 0
        }
    }
    
    func loadAllStatusCounts() async {
        var counts: [ReceiptStatus: Int] = [:]
        for status in ReceiptStatus.allCases {
            do {
                let count = try await donationRepository.countReceiptsByStatus(status)
                counts[status] = count
            } catch {
                print("Error loading count for \(status): \(error)")
                counts[status] = 0
            }
        }
        await MainActor.run {
            self.statusCounts = counts
        }
    }
    
    func filterReceipts(_ searchText: String) {
        if searchText.isEmpty {
            filteredReceipts = allReceipts
        } else {
            filteredReceipts = allReceipts.filter { receipt in
                receipt.donorName.localizedCaseInsensitiveContains(searchText) ||
                receipt.campaignName?.localizedCaseInsensitiveContains(searchText) ?? false ||
                String(receipt.donationId).contains(searchText)
            }
        }
    }
    
    func markAsRequested(receipt: ReceiptItem) async {
        do {
            try await donationRepository.updateReceiptStatus(donationId: receipt.donationId, status: .requested)
            await refreshReceipts()
        } catch {
            print("Error marking receipt as requested: \(error)")
        }
    }
    
    func markAsPrinted(receipt: ReceiptItem) async {
        do {
            try await donationRepository.updateReceiptStatus(donationId: receipt.donationId, status: .printed)
            await refreshReceipts()
        } catch {
            print("Error marking receipt as printed: \(error)")
        }
    }
    
    func markAsFailed(receipt: ReceiptItem) async {
        do {
            try await donationRepository.updateReceiptStatus(donationId: receipt.donationId, status: .failed)
            await refreshReceipts()
        } catch {
            print("Error marking receipt as failed: \(error)")
        }
    }
    
    func markAsQueued(receipt: ReceiptItem) async {
        do {
            try await donationRepository.updateReceiptStatus(donationId: receipt.donationId, status: .queued)
            await refreshReceipts()
        } catch {
            print("Error marking receipt as queued: \(error)")
        }
    }
    
    func printReceipt(receipt: ReceiptItem) async {
        // First, mark the receipt as queued
        await markAsQueued(receipt: receipt)
        
        do {
            // Get the donation and donor details
            guard let donation = try await donationRepository.getOne(receipt.donationId) else {
                throw NSError(domain: "ReceiptPrinting", code: 1, userInfo: [NSLocalizedDescriptionKey: "Donation not found"])
            }
            
            var donorName = "Anonymous"
            var donorTitle: String? = nil
            if let donorId = donation.donorId, !donation.isAnonymous {
                if let donor = try? await donationRepository.getDonorForDonation(donorId: donorId) {
                    donorName = "\(donor.firstName ?? "") \(donor.lastName ?? "")"
                    if donorName.trimmingCharacters(in: .whitespaces).isEmpty {
                        donorName = donor.company ?? "Unknown"
                    }
                    donorTitle = donor.salutation
                }
            }
            
            // Format date for display
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = dateFormatter.string(from: donation.donationDate)
            
            // Create donation info using the proper format
            let donationInfo = DonationInfo(
                donorName: donorName,
                donorTitle: donorTitle,
                donationAmount: donation.amount,
                date: dateString,
                donorAddress: nil,
                donorCity: nil,
                donorState: nil,
                donorZip: nil,
                receiptNumber: nil
            )
            
            // Create receipt printing service
            let printingService = ReceiptPrintingService()
            
            // Print the receipt on the main thread since it involves UI
            await MainActor.run {
                printingService.printReceipt(for: donationInfo) { success in
                    // This completion handler will run after printing completes or is cancelled
                    Task {
                        if success {
                            await self.markAsPrinted(receipt: receipt)
                        } else {
                            // User cancelled - mark as requested again
                            await self.markAsRequested(receipt: receipt)
                        }
                    }
                }
            }
            
        } catch {
            print("Error printing receipt: \(error)")
            await markAsFailed(receipt: receipt)
        }
    }
}

class ReceiptService {
    private let donationRepository: DonationRepository
    private let printingService = ReceiptPrintingService()
    
    init(donationRepository: DonationRepository) {
        self.donationRepository = donationRepository
    }
    
    func getReceipts(with status: ReceiptStatus) async throws -> [ReceiptItem] {
        let donations = try await donationRepository.getReceiptRequests(status: status)
        return try await convertDonationsToReceipts(donations)
    }
    
    func markAsPrinted(donationId: Int) async throws {
        try await donationRepository.updateReceiptStatus(donationId: donationId, status: .printed)
    }
    
    func markAsFailed(donationId: Int) async throws {
        try await donationRepository.updateReceiptStatus(donationId: donationId, status: .failed)
    }
    
    func markAsQueued(donationId: Int) async throws {
        try await donationRepository.updateReceiptStatus(donationId: donationId, status: .queued)
    }
    
    func markAsRequested(donationId: Int) async throws {
        try await donationRepository.updateReceiptStatus(donationId: donationId, status: .requested)
    }
    
    func countPendingReceipts() async throws -> Int {
        try await donationRepository.countPendingReceipts()
    }
    
    private func convertDonationsToReceipts(_ donations: [Donation]) async throws -> [ReceiptItem] {
        var receiptItems: [ReceiptItem] = []
        
        for donation in donations {
            // Get donor name
            var donorName = "Anonymous"
            if let donorId = donation.donorId, !donation.isAnonymous {
                if let donor = try? await donationRepository.getDonorForDonation(donorId: donorId) {
                    donorName = "\(donor.firstName ?? "") \(donor.lastName ?? "")"
                    if donorName.trimmingCharacters(in: .whitespaces).isEmpty {
                        donorName = donor.company ?? "Unknown"
                    }
                }
            }
            
            // Get campaign name
            var campaignName: String? = nil
            if let campaignId = donation.campaignId {
                if let campaign = try? await donationRepository.getCampaignForDonation(campaignId: campaignId) {
                    campaignName = campaign.name
                }
            }
            
            // Create receipt item
            let receiptItem = ReceiptItem(
                id: UUID(),
                donationId: donation.id ?? 0,
                donorName: donorName,
                amount: donation.amount,
                date: donation.donationDate,
                campaignName: campaignName,
                status: donation.receiptStatus
            )
            
            receiptItems.append(receiptItem)
        }
        
        return receiptItems
    }
    
    func printReceipt(for donation: Donation) async throws {
        // Get donor details
        print("Printing receipt for donation ID: \(donation.id ?? 0)")
        var donorName = "Anonymous"
        var donorTitle: String? = nil
        var donorAddress: String? = nil
        var donorCity: String? = nil
        var donorState: String? = nil
        var donorZip: String? = nil
        
        if let donorId = donation.donorId, !donation.isAnonymous {
            if let donor = try? await donationRepository.getDonorForDonation(donorId: donorId) {
                donorName = "\(donor.firstName ?? "") \(donor.lastName ?? "")"
                if donorName.trimmingCharacters(in: .whitespaces).isEmpty {
                    donorName = donor.company ?? "Unknown"
                }
                // GET: Address and title information
                donorTitle = donor.salutation
                donorAddress = donor.address
                donorCity = donor.city
                donorState = donor.state
                donorZip = donor.zip
            }
        }
        
        // Format date for display
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: donation.donationDate)
        
        // Create donation info
        let donationInfo = DonationInfo(
            donorName: donorName,
            donorTitle: donorTitle,
            donationAmount: donation.amount,
            date: dateString,
            donorAddress: donorAddress,
            donorCity: donorCity,
            donorState: donorState,
            donorZip: donorZip,
            receiptNumber: donation.receiptNumber ?? ""
        )
        
        // Create a task completion source to handle the async completion
        let taskCompletionSource = TaskCompletionSource<Void>()
        
        // Print the receipt on the main thread
        await MainActor.run {
            let printingService = ReceiptPrintingService()
            printingService.printReceipt(for: donationInfo) { success in
                // Update status after printing is complete
                Task {
                    if success {
                        try? await self.markAsPrinted(donationId: donation.id ?? 0)
                        taskCompletionSource.fulfill(())
                    } else {
                        // User cancelled - mark as requested again
                        try? await self.donationRepository.updateReceiptStatus(donationId: donation.id ?? 0, status: .requested)
                        taskCompletionSource.reject(NSError(domain: "ReceiptPrinting", code: 2, userInfo: [NSLocalizedDescriptionKey: "User cancelled printing"]))
                    }
                }
            }
        }
        
        // Wait for the printing to complete
        try await taskCompletionSource.task.value
    }
    
    func batchPrintReceipts(with status: ReceiptStatus = .requested) async throws -> (Int, Int) {
        let donations = try await donationRepository.getReceiptRequests(status: status)
        var successCount = 0
        var failureCount = 0
        
        for donation in donations {
            do {
                // Mark as queued first
                try await donationRepository.updateReceiptStatus(donationId: donation.id ?? 0, status: .queued)
                
                // Try to print
                try await printReceipt(for: donation)
                
                // If successful, increment counter
                successCount += 1
            } catch {
                // If failed, mark as failed and increment failure counter
                try? await donationRepository.updateReceiptStatus(donationId: donation.id ?? 0, status: .failed)
                failureCount += 1
            }
        }
        
        return (successCount, failureCount)
    }
}

class TaskCompletionSource<T> {
    var task: Task<T, Error> {
        return Task {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        }
    }
    
    private var continuation: CheckedContinuation<T, Error>?
    
    func fulfill(_ value: T) {
        continuation?.resume(returning: value)
        continuation = nil
    }
    
    func reject(_ error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

struct PrintReceiptSheetView: View {
    let receipts: [ReceiptItem]
    let onCompletion: (Int, Int, Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var isPrinting = false
    @State private var statusMessage = ""
    
    private let receiptService: ReceiptService
    private let donationRepository: DonationRepository
    private let printingService = ReceiptPrintingService()
    
    init(receipts: [ReceiptItem], onCompletion: @escaping (Int, Int, Int) -> Void) {
        self.receipts = receipts
        self.onCompletion = onCompletion
        self.donationRepository = try! DonationRepository()
        self.receiptService = ReceiptService(donationRepository: self.donationRepository)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "printer.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Print Receipts")
                .font(.title)
                .bold()
            
            if isPrinting {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text(statusMessage)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Ready to print \(receipts.count) receipt(s)")
                    .foregroundColor(.secondary)
                
                Text("All receipts will be combined into a single PDF")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button {
                    startBatchPrinting()
                } label: {
                    Text("Print Now")
                        .padding(.horizontal, 20)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isPrinting)
            }
            .padding()
        }
        .padding()
        .frame(minWidth: 300, minHeight: 400)
    }
    
    private func startBatchPrinting() {
        isPrinting = true
        statusMessage = "Preparing receipts..."
        
        Task {
            // Mark all receipts as queued first
            for receipt in receipts {
                try? await receiptService.markAsQueued(donationId: receipt.donationId)
            }
            
            // Gather all DonationInfo objects
            var donationInfos: [DonationInfo] = []
            
            await MainActor.run {
                statusMessage = "Generating PDF..."
            }
            
            for receipt in receipts {
                if let donationInfo = await getDonationInfo(for: receipt) {
                    donationInfos.append(donationInfo)
                }
            }
            
            // Check if we have any donations to print
            guard !donationInfos.isEmpty else {
                await handleBatchFailure()
                return
            }
            
            await MainActor.run {
                statusMessage = "Opening print dialog..."
            }
            
            // Print all receipts at once
            await MainActor.run {
                printingService.printReceipts(for: donationInfos) { success in
                    Task {
                        if success {
                            await handleBatchSuccess()
                        } else {
                            // User cancelled - return all to requested
                            await handleBatchCancelled()
                        }
                    }
                }
            }
        }
    }
    
    private func getDonationInfo(for receipt: ReceiptItem) async -> DonationInfo? {
        guard let donation = try? await donationRepository.getOne(receipt.donationId) else {
            return nil
        }
        
        var donorName = "Anonymous"
        var donorTitle: String? = nil
        var donorAddress: String? = nil
        var donorCity: String? = nil
        var donorState: String? = nil
        var donorZip: String? = nil
        
        if let donorId = donation.donorId, !donation.isAnonymous {
            if let donor = try? await donationRepository.getDonorForDonation(donorId: donorId) {
                donorName = "\(donor.firstName ?? "") \(donor.lastName ?? "")"
                if donorName.trimmingCharacters(in: .whitespaces).isEmpty {
                    donorName = donor.company ?? "Unknown"
                }
                donorTitle = donor.salutation
                donorAddress = donor.address
                donorCity = donor.city
                donorState = donor.state
                donorZip = donor.zip
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: donation.donationDate)
        
        return DonationInfo(
            donorName: donorName,
            donorTitle: donorTitle,
            donationAmount: donation.amount,
            date: dateString,
            donorAddress: donorAddress,
            donorCity: donorCity,
            donorState: donorState,
            donorZip: donorZip,
            receiptNumber: donation.receiptNumber
        )
    }
    
    private func handleBatchSuccess() async {
        // Mark all receipts as printed
        for receipt in receipts {
            try? await receiptService.markAsPrinted(donationId: receipt.donationId)
        }
        
        await MainActor.run {
            isPrinting = false
            dismiss()
            onCompletion(receipts.count, receipts.count, 0)
        }
    }
    
    private func handleBatchCancelled() async {
        // Return all receipts to requested status
        for receipt in receipts {
            try? await receiptService.markAsRequested(donationId: receipt.donationId)
        }
        
        await MainActor.run {
            isPrinting = false
            dismiss()
            onCompletion(0, receipts.count, 0)
        }
    }
    
    private func handleBatchFailure() async {
        // Mark all receipts as failed
        for receipt in receipts {
            try? await receiptService.markAsFailed(donationId: receipt.donationId)
        }
        
        await MainActor.run {
            isPrinting = false
            dismiss()
            onCompletion(0, receipts.count, receipts.count)
        }
    }
}

// MARK: - Previews
#Preview("Receipt Management - Requested") {
    NavigationView {
        ReceiptManagementView()
    }
}
