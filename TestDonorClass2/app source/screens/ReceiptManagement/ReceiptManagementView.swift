//
//  ReceiptManagementView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 3/5/25.
//

import SwiftUI

struct ReceiptManagementView: View {
    @StateObject private var viewModel = ReceiptManagementViewModel()
    @State private var showingPrintingSheet = false
    @State private var selectedStatus: ReceiptStatus = .requested
    @State private var searchText = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Receipt Status Filter
            Picker("Filter", selection: $selectedStatus) {
                ForEach(ReceiptStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: selectedStatus) { _ in
                Task {
                    await viewModel.loadReceipts(status: selectedStatus)
                }
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
                            ReceiptRowView(receipt: receiptItem)
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
                                }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                
                // Action Buttons
                HStack {
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await viewModel.refreshReceipts()
                        }
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    
                    if !viewModel.filteredReceipts.isEmpty {
                        Button(action: {
                            showingPrintingSheet = true
                        }) {
                            Label("Print All", systemImage: "printer")
                                .padding(.horizontal, 10)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Receipt Management")
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Receipt Status"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingPrintingSheet) {
            PrintReceiptSheetView(
                receipts: viewModel.selectedReceipt != nil ?
                    [viewModel.selectedReceipt!] : viewModel.filteredReceipts,
                onCompletion: { success, total, failed in
                    showingAlert = true
                    if failed == 0 {
                        alertMessage = "Successfully printed \(success) receipt(s)"
                    } else {
                        alertMessage = "Printed \(success) receipt(s). Failed to print \(failed) receipt(s)."
                    }
                    
                    Task {
                        await viewModel.refreshReceipts()
                    }
                }
            )
        }
        .onAppear {
            Task {
                await viewModel.loadReceipts(status: selectedStatus)
            }
        }
    }
}

struct ReceiptRowView: View {
    let receipt: ReceiptItem
    
    var body: some View {
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

//enum ReceiptStatus: String, Codable, CaseIterable {
//    case notRequested
//    case requested
//    case queued
//    case printed
//    case failed
//
//    var displayName: String {
//        switch self {
//        case .notRequested: return "Not Requested"
//        case .requested: return "Requested"
//        case .queued: return "Queued"
//        case .printed: return "Printed"
//        case .failed: return "Failed"
//        }
//    }
//}

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
    
    private let donationRepository: DonationRepository
    
    init(donationRepository: DonationRepository = DonationRepository()) {
        self.donationRepository = donationRepository
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
            if let donorId = donation.donorId, !donation.isAnonymous {
                if let donor = try? await donationRepository.getDonorForDonation(donorId: donorId) {
                    donorName = "\(donor.firstName ?? "") \(donor.lastName ?? "")"
                    if donorName.trimmingCharacters(in: .whitespaces).isEmpty {
                        donorName = donor.company ?? "Unknown"
                    }
                }
            }
            
            // Format date for display
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = dateFormatter.string(from: donation.donationDate)
            
            // Create donation info using the proper format
            let donationInfo = DonationInfo(
                donorName: donorName,
                donationAmount: donation.amount,
                date: dateString
            )
            
            // Create receipt printing service
            let printingService = ReceiptPrintingService()
            
            // Print the receipt on the main thread since it involves UI
            await MainActor.run {
                printingService.printReceipt(for: donationInfo) {
                    // This completion handler will run after printing completes or is cancelled
                    Task {
                        await self.markAsPrinted(receipt: receipt)
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
    
    init(donationRepository: DonationRepository = DonationRepository()) {
        self.donationRepository = donationRepository
    }
    
    // Other methods remain the same
    
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
        if let donorId = donation.donorId, !donation.isAnonymous {
            if let donor = try? await donationRepository.getDonorForDonation(donorId: donorId) {
                donorName = "\(donor.firstName ?? "") \(donor.lastName ?? "")"
                if donorName.trimmingCharacters(in: .whitespaces).isEmpty {
                    donorName = donor.company ?? "Unknown"
                }
            }
        }
        
        // Format date for display
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: donation.donationDate)
        
        // Create donation info
        let donationInfo = DonationInfo(
            donorName: donorName,
            donationAmount: donation.amount,
            date: dateString
        )
        
        // Create a task completion source to handle the async completion
        let taskCompletionSource = TaskCompletionSource<Void>()
        
        // Print the receipt on the main thread
        await MainActor.run {
            let printingService = ReceiptPrintingService()
            printingService.printReceipt(for: donationInfo) {
                // Update status after printing is complete
                Task {
                    try? await self.markAsPrinted(donationId: donation.id ?? 0)
                    taskCompletionSource.fulfill(())
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
    @State private var progress = 0.0
    @State private var successCount = 0
    @State private var failureCount = 0
    @State private var currentReceiptIndex = 0
    
    private let receiptService = ReceiptService()
    private let donationRepository = DonationRepository()
    
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
                    ProgressView(value: progress, total: 1.0)
                        .padding()
                    
                    Text("Printing \(progress * 100, specifier: "%.0f")%")
                        .foregroundColor(.secondary)
                    
                    if successCount > 0 || failureCount > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            if successCount > 0 {
                                Text("Success: \(successCount)")
                                    .foregroundColor(.green)
                            }
                            if failureCount > 0 {
                                Text("Failed: \(failureCount)")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            } else {
                Text("Ready to print \(receipts.count) receipt(s)")
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
                    startPrinting()
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
    
    private func startPrinting() {
        isPrinting = true
        currentReceiptIndex = 0
        successCount = 0
        failureCount = 0
        
        // Start printing the first receipt
        printNextReceipt()
    }
    
    private func printNextReceipt() {
        let totalReceipts = receipts.count
        
        // If we've processed all receipts, finish up
        if currentReceiptIndex >= totalReceipts {
            // Short delay to show final progress
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isPrinting = false
                dismiss()
                onCompletion(successCount, totalReceipts, failureCount)
            }
            return
        }
        
        // Update progress
        let receipt = receipts[currentReceiptIndex]
        progress = Double(currentReceiptIndex) / Double(totalReceipts)
        
        // Process the current receipt
        Task {
            do {
                // Mark as queued first
                try await receiptService.markAsQueued(donationId: receipt.donationId)
                
                // Get the full donation record
                if let donation = try await donationRepository.getOne(receipt.donationId) {
                    // Get donor details
                    var donorName = "Anonymous"
                    if let donorId = donation.donorId, !donation.isAnonymous {
                        if let donor = try? await donationRepository.getDonorForDonation(donorId: donorId) {
                            donorName = "\(donor.firstName ?? "") \(donor.lastName ?? "")"
                            if donorName.trimmingCharacters(in: .whitespaces).isEmpty {
                                donorName = donor.company ?? "Unknown"
                            }
                        }
                    }
                    
                    // Format date for display
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    let dateString = dateFormatter.string(from: donation.donationDate)
                    
                    // Create donation info using the standard format
                    let donationInfo = DonationInfo(
                        donorName: donorName,
                        donationAmount: donation.amount,
                        date: dateString
                    )
                    
                    // Print the receipt
                    let printingService = ReceiptPrintingService()
                    
                    // Use MainActor since printing involves UI
                    await MainActor.run {
                        printingService.printReceipt(for: donationInfo) {
                            // This completion handler will run after printing completes or is cancelled
                            Task {
                                // Mark receipt as printed
                                try? await receiptService.markAsPrinted(donationId: receipt.donationId)
                                
                                // Update success count
                                await MainActor.run {
                                    successCount += 1
                                    // Move to the next receipt
                                    currentReceiptIndex += 1
                                    progress = Double(currentReceiptIndex) / Double(totalReceipts)
                                    printNextReceipt()
                                }
                            }
                        }
                    }
                    
                } else {
                    throw NSError(domain: "PrintReceipt", code: 1, userInfo: [NSLocalizedDescriptionKey: "Donation not found"])
                }
            } catch {
                print("Error printing receipt: \(error)")
                
                // Mark as failed
                try? await receiptService.markAsFailed(donationId: receipt.donationId)
                
                // Update failure count
                await MainActor.run {
                    failureCount += 1
                    // Move to the next receipt
                    currentReceiptIndex += 1
                    progress = Double(currentReceiptIndex) / Double(totalReceipts)
                    printNextReceipt()
                }
            }
        }
    }
}
