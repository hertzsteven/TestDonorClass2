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

    var body: some View {
        VStack(spacing: 0) {
            globalSettingsBar
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
                Text("Status:")
                    .foregroundColor(.secondary)
                Menu {
                    ForEach([PaymentStatus.completed, .pending], id: \.self) { status in
                        Button(status.rawValue.capitalized) {
                            viewModel.globalPaymentStatus = status
                        }
                    }
                } label: {
                    Text(viewModel.globalPaymentStatus.rawValue.capitalized)
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
            Text("Status")
                .frame(width: 50)
            Text("Donor ID")
                .frame(width: 70)
            Text("Last Name")
                .frame(width: 100)
            Text("Name & Address")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Receipt")
                .frame(width: 60)
            Text("Type")
                .frame(width: 90)
            Text("Pay Status")
                .frame(width: 90)
            Text("Amount")
                .frame(width: 50, alignment: .trailing)
            Text("Action")
                .frame(width: 50)
        }
        .font(.caption.bold())
        .foregroundColor(.secondary)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(Color(.systemGray6).opacity(0.7))
                .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
        )
        .padding(.horizontal)
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
        HStack {
            // Status Icon
            Image(systemName: statusIcon(for: r.processStatus))
                .foregroundColor(statusColor(for: r.processStatus))
                .frame(width: 50, alignment: .center)

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
                TextField("Last Name", text: row.lastNameSearch)
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
            HStack(alignment: .center, spacing: 8) {
                Text(r.isValidDonor ? getDonorName(from: r.displayInfo) : (r.displayInfo.isEmpty && r.donorID == nil ? "Enter ID or Search" : r.displayInfo))
                    .font(r.isValidDonor ? .subheadline : .caption)
                    .foregroundColor(r.isValidDonor ? .primary : (r.displayInfo.contains("Error") || r.displayInfo.contains("not found") ? .red : .secondary))
                    .lineLimit(1)
                    .frame(minWidth: 180, maxWidth: 280, alignment: .leading)
                
                if r.isValidDonor {
                    Text(getDonorAddress(from: r.displayInfo))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: 120, alignment: .leading)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 40, alignment: .center)
            .help(r.displayInfo)

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
                // Text("Default (\(viewModel.globalDonationType.rawValue))").tag(viewModel.globalDonationType)
                ForEach(DonationType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 90)
            .disabled(!r.isValidDonor)

            // Payment Status Override
            Picker("", selection: row.paymentStatusOverride) {
                 // Text("Default (\(viewModel.globalPaymentStatus.rawValue.capitalized))").tag(viewModel.globalPaymentStatus)
                ForEach([PaymentStatus.completed, .pending], id: \.self) { status in
                    Text(status.rawValue.capitalized).tag(status)
                }
            }
           .pickerStyle(.menu)
           .frame(width: 90)
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
         case .none: return "circle"
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
            return components.dropFirst().joined(separator: ", ")
        }
        return ""
    }
}

//  MARK: - Toolbar Builder
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