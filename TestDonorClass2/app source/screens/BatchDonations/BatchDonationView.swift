//
//  BatchDonationView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/30/25.
//

import SwiftUI

struct BatchDonationView: View {
    // ... (EnvironmentObjects, StateObject, init remain the same) ...
    @EnvironmentObject private var donorObject: DonorObjectClass
    @EnvironmentObject private var donationObject: DonationObjectClass
    @EnvironmentObject var campaignObject: CampaignObjectClass
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: BatchDonationViewModel

    @State private var selectedCampaign: Campaign?
    @State private var showingDonorSearch = false
    @State private var currentRowID: UUID? = nil
    @State private var initialSearchText: String? = nil
    @FocusState private var focusedRowID: UUID?

    @State private var showingSaveSummary = false
    @State private var saveResult: (success: Int, failed: Int, totalAmount: Double)? = nil
    
    // Existing code...
    @State private var showingPrayerNoteSheet = false
    @State private var selectedDonorForPrayer: Donor? = nil
    @State private var currentPrayerNote: String = ""
    @State private var currentPrayerRowID: UUID? = nil
    
    @State private var showingClearAllConfirmation = false

    // Custom Initializer
    init() {
        do {
            let donorRepo = try! DonorRepository()

//            let donorRepo = try! MockDonorRepository()
             let donationRepo = try! DonationRepository()
             _viewModel = StateObject(wrappedValue: BatchDonationViewModel(
                 repository: donorRepo,
                 donationRepository: donationRepo
             ))
         } catch {
              fatalError("Failed to initialize repositories for BatchDonationView: \(error)")
         }
    }

    /// Initializer for previews that accepts mock repositories
    init(donorRepo: any DonorSpecificRepositoryProtocol, donationRepo: any DonationSpecificRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: BatchDonationViewModel(
            repository: donorRepo,
            donationRepository: donationRepo
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            globalSettingsBar

            Divider()
                .padding(.horizontal, 0)
                .padding(.bottom, 12)
                .background(Color(.systemGray6)) // extra subtlety

            columnHeaders
            donationRowsList
        }
        .navigationTitle("Batch Donations")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingDonorSearch) {
            donorSearchSheet
        }
        .alert("Batch Save Summary", isPresented: $showingSaveSummary, presenting: saveResult) { result in
            saveSummaryAlert(result)
        } message: { result in
            Text("Successfully saved: \(result.success)\nFailed: \(result.failed)\nTotal Amount: \(formatCurrency(result.totalAmount))")
        }
        .alert("Clear All Entries", isPresented: $showingClearAllConfirmation) {
            clearAllAlert
        } message: {
            Text("Are you sure you want to clear all entries? This action cannot be undone.")
        }
        .sheet(isPresented: $showingPrayerNoteSheet, onDismiss: {
            prayerNoteSheetDismissed()
        }) {
            prayerNoteSheet
        }
        .task {
            await campaignObject.loadCampaigns()
        }
    }
    
    // MARK: - View Components
    
    private var globalSettingsBar: some View {
        HStack(spacing: 20) {
            Text("Global Settings:")
                .font(.headline)
            HStack(spacing: 8) {
                Text("Amount:")
                    .foregroundColor(.secondary)
                TextField("", value: $viewModel.globalDonation, format: .currency(code: "USD"))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }

            HStack(spacing: 8) {
                Text("Campaign:")
                    .foregroundColor(.secondary)
                Menu {
                    Button("None") {
                        selectedCampaign = nil
                    }
                    ForEach(campaignObject.campaigns.filter( {$0.status == .active})  ) { campaign in
                        Button(campaign.name) {
                            selectedCampaign = campaign
                        }
                    }
                } label: {
                    Text(selectedCampaign?.name ?? "None")
                        .foregroundColor(.blue)
                }
            }

            HStack(spacing: 8) {
                Text("Type:")
                    .foregroundColor(.secondary)
                Menu {
                    ForEach(DonationType.allCases, id: \.self) { type in
                        Button(type.rawValue) {
                            viewModel.globalDonationType = type
                        }
                    }
                } label: {
                    Text(viewModel.globalDonationType.rawValue)
                        .foregroundColor(.blue)
                }
            }

            HStack(spacing: 8) {
                Text("Receipt:")
                    .foregroundColor(.secondary)
                Toggle("", isOn: $viewModel.globalPrintReceipt)
                    .labelsHidden()
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private var columnHeaders: some View {
        HStack {
            Text("")
                .frame(width: 50)
            Text("ID")
                .frame(width: 70)
            Text("Name")
                .frame(width: 100)
            Text("")
                .frame(width: 60)
            Text("Address")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 40)
            Text("Request")
                .frame(width: 70, alignment: .trailing)
                .font(.body.bold())
                .lineLimit(1)
                .padding(.leading, 15)
            Text("Receipt")
                .frame(width: 70, alignment: .trailing)
                .font(.body.bold())
                .lineLimit(1)
                .padding(.leading, 10)
            Text("Type")
                .frame(width: 60, alignment: .center)
                .padding(.leading, 15)
            Text("Amount")
                .frame(width: 90, alignment: .leading)
                .padding(.leading, 10)
            Text("")
                .frame(width: 50)
        }
        .font(.body.bold())
        .foregroundColor(.secondary)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(Color(.systemGray6).opacity(0.7))
                .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
        )
    }
    
    private var donationRowsList: some View {
        List {
            ForEach(Array(viewModel.rows.enumerated()), id: \.element.id) { index, _ in
                batchRowView(row: $viewModel.rows[index])
                    .focused($focusedRowID, equals: viewModel.rows[index].id)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.visible)
                    .listRowBackground(
                        index % 2 == 0 ?
                        Color(.systemBackground) :
                        Color(.systemGray6).opacity(0.3)
                    )
            }
        }
        .listStyle(.plain)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
    }
    
    // MARK: - Toolbar and Sheets
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    if !viewModel.rows.contains(where: { $0.isValidDonor }) {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    if viewModel.rows.contains(where: { $0.isValidDonor }) {
                        Button("Clear All", role: .destructive) {
                            showingClearAllConfirmation = true
                        }
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.rows.contains(where: { $0.isValidDonor }) {
                    Button("Save Batch") {
                        Task {
                            saveResult = await viewModel.saveBatchDonations(selectedCampaignId: selectedCampaign?.id)
                            showingSaveSummary = true
                        }
                    }
                    .foregroundColor(.blue)
                    .disabled(viewModel.rows.allSatisfy { !$0.isValidDonor })
                }
            }
        }
    }
    
    private var donorSearchSheet: some View {
        DonorSearchSelectionView(onDonorSelected: { selectedDonor in
            if let rowID = currentRowID {
                Task {
                    await viewModel.setDonorFromSearch(selectedDonor, for: rowID)
                    currentRowID = nil
                    initialSearchText = nil
                }
            } else {
                  print("Error: currentRowID was nil when donor search returned.")
             }
         }, initialSearchText: initialSearchText)
         .environmentObject(donorObject)
    }
    
    private func saveSummaryAlert(_ result: (success: Int, failed: Int, totalAmount: Double)) -> some View {
        Button("OK") {
            if result.failed == 0 && result.success > 0 {
                viewModel.clearBatch()
            }
            saveResult = nil
        }
    }
    
    private var clearAllAlert: some View {
        Group {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                viewModel.clearBatch()
            }
        }
    }
    
    private var prayerNoteSheet: some View {
        Group {
            if let donor = selectedDonorForPrayer {
                PrayerNoteSheet(
                    donor: donor,
                    prayerNote: $currentPrayerNote
                )
            } else {
                PrayerNoteSheet(
                    donor: nil,
                    prayerNote: $currentPrayerNote
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func prayerNoteSheetDismissed() {
        // When dismissed, update the note in the model
        if let rowIndex = viewModel.rows.firstIndex(where: { $0.id == currentPrayerRowID }) {
            viewModel.rows[rowIndex].prayerNote = currentPrayerNote
            // If the note is empty, turn off the toggle
            if currentPrayerNote.isEmpty {
                viewModel.rows[rowIndex].prayerNoteSW = false
            }
        }
    }

    @ViewBuilder
    private func batchRowView(row: Binding<BatchDonationViewModel.RowEntry>) -> some View {
        let r = row.wrappedValue // Access wrapped value for reading non-binding properties
        HStack(alignment: .bottom) {
            // Status Icon - Only show when processing has occurred
            Group {
                if r.processStatus != .none {
                    Image(systemName: statusIcon(for: r.processStatus))
                        .foregroundColor(statusColor(for: r.processStatus))
                        .frame(width: 50, alignment: .center)
                } else {
                    // Empty space when no processing status
                    Color.clear
                        .frame(width: 50, alignment: .center)
                }
            }

            // Donor ID
            TextField("ID", value: row.donorID, format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 70)
                .keyboardType(.numberPad)
                .disabled(r.isValidDonor) // Add this line to disable the field when a donor is valid
                .foregroundColor(r.isValidDonor ? .gray : .primary) // Gray out text when disabled
                .background(r.isValidDonor ? Color(.systemGray6) : Color(.systemBackground)) // Optional background change
                .onSubmit {
                     Task { await viewModel.findDonor(for: r.id) }
                 }

            // Last Name Search Field - Only show when no valid donor
            if !r.isValidDonor {
                TextField("Name", text: row.lastNameSearch)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
                    .onSubmit {
                        if !r.lastNameSearch.isEmpty {
                            currentRowID = r.id
                            initialSearchText = r.lastNameSearch
                            showingDonorSearch = true
                        }
                    }

                // Search Button - Only show when no valid donor
                Button {
                    currentRowID = r.id
                    initialSearchText = r.lastNameSearch.isEmpty ? nil : r.lastNameSearch
                    showingDonorSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
                .frame(width: 60, height: 32)
                .background(Color(.systemGray5))
                .cornerRadius(6)
                .buttonStyle(PlainButtonStyle())
            }

            // Donor Info Display
            HStack(alignment: .center, spacing: 12) {
                Text(r.isValidDonor ? getDonorName(from: r.displayInfo) : (r.displayInfo.isEmpty && r.donorID == nil ? "Enter ID or Name" : r.displayInfo))
                    .font(r.isValidDonor ? .subheadline : .caption)
                    .foregroundColor(r.isValidDonor ? .primary : (r.displayInfo.contains("Error") || r.displayInfo.contains("not found") ? .red : .secondary))
                    .lineLimit(1)
                    .frame(minWidth: 120, maxWidth: 160, alignment: .leading)
                
                if r.isValidDonor {
                    Text(getDonorAddress(from: r.displayInfo))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 40, alignment: .center)
            .help(r.displayInfo)
            .padding(.leading, 20)

            // Prayer Note Toggle
            Toggle("Pray", isOn: row.prayerNoteSW)
                .labelsHidden()
//                .frame(width: 60, alignment: .center)
                .toggleStyle(.button)
                .disabled(!r.isValidDonor)
                .onChange(of: row.prayerNoteSW.wrappedValue) { oldValue, newValue in
                        if newValue {
                            currentPrayerRowID = r.id
                            // Get the donor information to display in the sheet
                            Task {
                                if let donorId = r.donorID {
                                    selectedDonorForPrayer = try? await donorObject.getDonor(donorId)
                                    currentPrayerNote = r.prayerNote ?? ""
                                    showingPrayerNoteSheet = true
                                }
                            }
                        }
                    }

            // Receipt Toggle
            Toggle("", isOn: row.printReceipt.animation())
                .labelsHidden()
                .frame(width: 60, alignment: .center)
                .disabled(!r.isValidDonor)

            // Donation Type Override
            Picker("", selection: row.donationTypeOverride) {
                ForEach(DonationType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 90, alignment: .center)
            .disabled(!r.isValidDonor)

            // Amount Override
            TextField("Amount", value: row.donationOverride, format: .currency(code: "USD"))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .frame(width: 80)
                .foregroundColor(r.hasDonationOverride ? .blue : .primary)
                .disabled(!r.isValidDonor)

            // Action Button (Search/Find/Delete)
            actionButton(row: row)
                .frame(width: 50, alignment: .center)
        }
        .padding(.vertical, 8)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(
                    r.isValidDonor ? Color.clear :
                        (r.displayInfo.contains("Error") || r.displayInfo.contains("not found") ?
                            Color.red.opacity(0.3) : Color.gray.opacity(0.3)),
                    lineWidth: 1
                )
                .padding(.horizontal, 8)
        )
    }

    // Extracted Action Button Logic
    @ViewBuilder
    private func actionButton(row: Binding<BatchDonationViewModel.RowEntry>) -> some View {
        let r = row.wrappedValue
        if r.isValidDonor {
            Button {
                viewModel.rows.removeAll { $0.id == r.id }
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())

        } else {
            // Show empty space when no valid donor instead of the three-dot menu
            Spacer()
        }
    }

    private func statusIcon(for status: BatchDonationViewModel.RowProcessStatus) -> String { 
         switch status {
         case .none: return "circle" // This won't be used anymore since we check for .none above
         case .success: return "checkmark.circle.fill"
         case .failure: return "xmark.octagon.fill"
         }
    }
    private func statusColor(for status: BatchDonationViewModel.RowProcessStatus) -> Color { 
         switch status {
         case .none: return .gray.opacity(0.5)
         case .success: return .green
         case .failure: return .red
         }
    }
    private func formatCurrency(_ amount: Double) -> String { 
          let formatter = NumberFormatter()
          formatter.numberStyle = .currency
          formatter.currencyCode = "USD"
          return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
      }

    func getDonorName(from donorInfo: String) -> String {
        let components = donorInfo.components(separatedBy: "\n")
        return components.first ?? donorInfo
    }
    
    func getDonorAddress(from donorInfo: String) -> String {
        let components = donorInfo.components(separatedBy: "\n")
        if components.count > 1 {
            let addressComponents = components.dropFirst()
            let addressString = addressComponents.joined(separator: ", ")
            // Remove leading/trailing whitespace and any leading periods or commas
            return addressString.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "^[.,\\s]+", with: "", options: .regularExpression)
        }
        return ""
    }

}

class MockDonationRepository: DonationSpecificRepositoryProtocol {
    
    typealias Model = Donation
    
    private var donations: [Donation] = []
    private var nextId = 1
    
    init() {
        print("MockDonationRepository initialized")
    }
    
    func insert(_ donation: Donation) async throws -> Donation {
        var newDonation = donation
        newDonation.id = nextId
        nextId += 1
        donations.append(newDonation)
        print("MockDonationRepository: Inserted donation with ID \(newDonation.id ?? -1)")
        return newDonation
    }
    
    func getAll() async throws -> [Donation] {
        return donations
    }
    
    func getCount() async throws -> Int {
        return donations.count
    }
    
    func getOne(_ id: Int) async throws -> Donation? {
        return donations.first { $0.id == id }
    }
    
    func update(_ donation: Donation) async throws {
        if let index = donations.firstIndex(where: { $0.id == donation.id }) {
            donations[index] = donation
        }
    }
    
    func delete(_ donation: Donation) async throws {
        donations.removeAll { $0.id == donation.id }
    }
    
    func deleteOne(_ id: Int) async throws {
        donations.removeAll { $0.id == id }
    }
    
    func getTotalDonationsAmount(forDonorId donorId: Int) async throws -> Double {
        return donations.filter { $0.donorId == donorId }.reduce(0) { $0 + $1.amount }
    }
    
    func getDonationsForCampaign(campaignId: Int) async throws -> [Donation] {
        return donations.filter { $0.campaignId == campaignId }
    }
    
    func getDonationsForDonor(donorId: Int) async throws -> [Donation] {
        return donations.filter { $0.donorId == donorId }
    }
    
    func countPendingReceipts() async throws -> Int {
        return donations.filter { $0.receiptStatus == .requested }.count
    }
    
    func updateReceiptStatus(donationId: Int, status: ReceiptStatus) async throws {
        if let index = donations.firstIndex(where: { $0.id == donationId }) {
            donations[index].receiptStatus = status
        }
    }
    
    func getReceiptRequests(status: ReceiptStatus) async throws -> [Donation] {
        return donations.filter { $0.receiptStatus == status }
    }
    
    func generateReceiptNumber() async throws -> String {
        "receipt number"
    }
    

}

class MockCampaignRepository: CampaignSpecificRepositoryProtocol {
    typealias Model = Campaign
    
    private var campaigns: [Campaign] = []
    
    init() {
        // Create sample campaigns
        campaigns = [
            Campaign(
                campaignCode: "2025-SPRING",
                name: "Spring 2025 Campaign",
                description: "Annual spring fundraising campaign",
                startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
                endDate: Calendar.current.date(byAdding: .month, value: 2, to: Date()),
                status: .active,
                goal: 50000.0
            ),
            Campaign(
                campaignCode: "2024-WINTER",
                name: "Winter 2024 Campaign",
                description: "Holiday season fundraising",
                startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()),
                endDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
                status: .completed,
                goal: 25000.0
            )
        ]
        
        // Assign IDs
        for i in campaigns.indices {
            campaigns[i].id = i + 1
        }
        
        print("MockCampaignRepository initialized with \(campaigns.count) campaigns")
    }
    
    func insert(_ campaign: Campaign) async throws -> Campaign {
        var newCampaign = campaign
        newCampaign.id = (campaigns.compactMap { $0.id }.max() ?? 0) + 1
        campaigns.append(newCampaign)
        return newCampaign
    }
    
    func getAll() async throws -> [Campaign] {
        return campaigns
    }
    
    func getCount() async throws -> Int {
        return campaigns.count
    }
    
    func getOne(_ id: Int) async throws -> Campaign? {
        return campaigns.first { $0.id == id }
    }
    
    func update(_ campaign: Campaign) async throws {
        if let index = campaigns.firstIndex(where: { $0.id == campaign.id }) {
            campaigns[index] = campaign
        }
    }
    
    func delete(_ campaign: Campaign) async throws {
        campaigns.removeAll { $0.id == campaign.id }
    }
    
    func deleteOne(_ id: Int) async throws {
        campaigns.removeAll { $0.id == id }
    }
}

extension BatchDonationView {
    @ToolbarContentBuilder
    func SaveCancelToolBar() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Clear All") {
                showingClearAllConfirmation = true
            }
            .tint(.red)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save Batch") {
                Task {
                     saveResult = await viewModel.saveBatchDonations(selectedCampaignId: selectedCampaign?.id)
                     showingSaveSummary = true
                }
            }
            .disabled(viewModel.rows.allSatisfy { !$0.isValidDonor })
        }
    }
}

#Preview("Batch Donations - Empty State", traits: .landscapeLeft) {
    NavigationStack {
        BatchDonationView(
            donorRepo: MockDonorRepository(),
            donationRepo: MockDonationRepository()
        )
    }
    .environmentObject(createMockDonorObject())
    .environmentObject(createMockDonationObject())
    .environmentObject(createMockCampaignObject())
}

#Preview("Batch Donations - With Data", traits: .landscapeLeft) {
    NavigationStack {
        BatchDonationView(
            donorRepo: MockDonorRepository(),
            donationRepo: MockDonationRepository()
        )
    }
    .environmentObject(createMockDonorObjectWithData())
    .environmentObject(createMockDonationObject())
    .environmentObject(createMockCampaignObjectWithData())
}

private func createMockDonorObject() -> DonorObjectClass {
    let mockRepo = MockDonorRepository()
    return DonorObjectClass(repository: mockRepo)
}

private func createMockDonorObjectWithData() -> DonorObjectClass {
    let mockRepo = MockDonorRepository()
    let donorObject = DonorObjectClass(repository: mockRepo)
    
    // Pre-populate with some test data
    Task {
        await donorObject.loadDonors()
    }
    
    return donorObject
}

private func createMockDonationObject() -> DonationObjectClass {
    let mockRepo = MockDonationRepository()
    return DonationObjectClass(repository: mockRepo)
}

private func createMockCampaignObject() -> CampaignObjectClass {
    let mockRepo = MockCampaignRepository()
    return CampaignObjectClass(repository: mockRepo)
}

private func createMockCampaignObjectWithData() -> CampaignObjectClass {
    let mockRepo = MockCampaignRepository()
    let campaignObject = CampaignObjectClass(repository: mockRepo)
    
    // Pre-populate with test data
    Task {
        await campaignObject.loadCampaigns()
    }
    
    return campaignObject
}
