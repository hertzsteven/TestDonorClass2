//
//  BatchDonationView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/30/25.
//

import SwiftUI

struct BatchDonationView: View {
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
    
    @State private var showingPrayerNoteSheet = false
    @State private var selectedDonorForPrayer: Donor? = nil
    @State private var currentPrayerNote: String = ""
    @State private var currentPrayerRowID: UUID? = nil
    
    @State private var showingClearAllConfirmation = false
    @State private var shouldClearOnDisappear = false

    // Custom Initializer
    init() {
        do {
            let donorRepo = try! DonorRepository()
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
                .background(Color(.systemGray6))

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
        .onDisappear {
            if shouldClearOnDisappear {
                viewModel.clearBatch()
                shouldClearOnDisappear = false
            }
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
                    ForEach(campaignObject.campaigns.filter { $0.status == .active }) { campaign in
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
            
            HStack(spacing: 8) {
                Text("Date:")
                    .foregroundColor(.secondary)
                DatePicker(
                    "",
                    selection: $viewModel.globalDonationDate,
                    displayedComponents: .date
                )
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
            Text("").frame(width: 50)
            Text("ID").frame(width: 70)
            Text("Name").frame(width: 100)
            Text("").frame(width: 60)
            Text("Address").frame(maxWidth: .infinity, alignment: .leading)
            Text("Request").frame(width: 70, alignment: .trailing).font(.body.bold()).lineLimit(1).padding(.leading, 15)
            Text("Receipt").frame(width: 70, alignment: .trailing).font(.body.bold()).lineLimit(1).padding(.leading, 10)
            Text("Type").frame(width: 60, alignment: .center).padding(.leading, 15)
            Text("Date").frame(width: 110, alignment: .center)
            Text("Amount").frame(width: 90, alignment: .leading).padding(.leading, 10)
            Text("").frame(width: 50)
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
            ForEach(viewModel.rows) { row in
                batchRowView(row: binding(for: row.id))
                    .focused($focusedRowID, equals: row.id)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.visible)
            }
        }
        .listStyle(.plain)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
    }

    private func binding(for id: UUID) -> Binding<BatchDonationViewModel.RowEntry> {
        Binding(
            get: {
                viewModel.rows.first(where: { $0.id == id }) ?? BatchDonationViewModel.RowEntry()
            },
            set: { newValue in
                if let idx = viewModel.rows.firstIndex(where: { $0.id == id }) {
                    viewModel.rows[idx] = newValue
                }
            }
        )
    }
    
    // MARK: - Toolbar and Sheets
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    if !viewModel.rows.contains(where: { $0.isValidDonor }) {
                        Button(action: { dismiss() }) {
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
                shouldClearOnDisappear = false
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
                PrayerNoteSheet(donor: donor, prayerNote: $currentPrayerNote)
            } else {
                PrayerNoteSheet(donor: nil, prayerNote: $currentPrayerNote)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func prayerNoteSheetDismissed() {
        if let rowIndex = viewModel.rows.firstIndex(where: { $0.id == currentPrayerRowID }) {
            viewModel.rows[rowIndex].prayerNote = currentPrayerNote
            if currentPrayerNote.isEmpty {
                viewModel.rows[rowIndex].prayerNoteSW = false
            }
        }
    }

    @ViewBuilder
    private func batchRowView(row: Binding<BatchDonationViewModel.RowEntry>) -> some View {
        let r = row.wrappedValue // Access wrapped value for reading non-binding properties
        HStack(alignment: .bottom) {
            Group {
                if r.processStatus != .none {
                    Image(systemName: statusIcon(for: r.processStatus))
                        .foregroundColor(statusColor(for: r.processStatus))
                        .frame(width: 50, alignment: .center)
                } else {
                    Color.clear.frame(width: 50, alignment: .center)
                }
            }

            TextField("ID", value: row.donorID, format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 70)
                .keyboardType(.numberPad)
                .disabled(r.isValidDonor)
                .foregroundColor(r.isValidDonor ? .gray : .primary)
                .background(r.isValidDonor ? Color(.systemGray6) : Color(.systemBackground))
                .onSubmit {
                     Task { await viewModel.findDonor(for: r.id) }
                 }

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

            Color.clear
                .frame(width: 70, height: 1)

            Color.clear
                .frame(width: 70, height: 1)

            // RESTORE: Prayer Note Toggle (safe now with id-based binding + deferred clear)
            Toggle("Pray", isOn: row.prayerNoteSW)
                .labelsHidden()
                .toggleStyle(.button)
                .disabled(!r.isValidDonor)
                .onChange(of: row.prayerNoteSW.wrappedValue) { oldValue, newValue in
                    if newValue {
                        currentPrayerRowID = r.id
                        Task {
                            if let donorId = r.donorID {
                                selectedDonorForPrayer = try? await donorObject.getDonor(donorId)
                                currentPrayerNote = r.prayerNote ?? ""
                                showingPrayerNoteSheet = true
                            }
                        }
                    }
                }

            // RESTORE: Receipt Toggle
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

            DatePicker("", selection: row.donationDate, displayedComponents: .date)
                .labelsHidden()
                .frame(width: 100, alignment: .center)
                .disabled(!r.isValidDonor)

            TextField("Amount", value: row.donationOverride, format: .currency(code: "USD"))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .frame(width: 80)
                .foregroundColor(r.hasDonationOverride ? .blue : .primary)
                .disabled(!r.isValidDonor)

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
            let addressComponents = components.dropFirst()
            return addressComponents.joined(separator: ", ").trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "^[.,\\s]+", with: "", options: .regularExpression)
        }
        return ""
    }
}
// Previews remain the same
#if DEBUG
// ... Previews ...
#endif