//
//  BatchPledgeView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 5/19/25.
//


//
//  BatchPledgeView.swift
//  Batch pledges
//
//  Created by Steven Hertz on 5/18/25.
//

import SwiftUI

// BatchPledgeView (and its subviews like MockDonorSearchView)
// from the previous response should be pasted here.
// Ensure all helper functions (statusIcon, statusColor, formatCurrency, isFailureStatus)
// are also included within BatchPledgeView.

struct BatchPledgeView: View {
    // Add this near the top of BatchPledgeView
    @EnvironmentObject var donorObject: DonorObjectClass
    // KEEP: viewModel and other state properties
    
    // @StateObject private var viewModel = BatchPledgeViewModel()
    @StateObject private var viewModel: BatchPledgeViewModel
    
    @State private var selectedCampaign: Campaign?
    @State private var showingDonorSearch = false
    @State private var currentRowIDForSearch: UUID? = nil
    @FocusState private var focusedRowID: UUID?
    @State private var showingSaveSummary = false
    @State private var saveResult: (success: Int, failed: Int, totalAmount: Double)? = nil
    @State private var showingPrayerNoteSheet = false
    @State private var currentPrayerNote: String = ""
    @State private var currentPrayerRowID: UUID? = nil
    @State private var selectedDonorForPrayer: Donor? = nil
    
    init() {
        do {
            let donorRepo = try! DonorRepository()
            _viewModel = StateObject(wrappedValue: BatchPledgeViewModel(
                repository: donorRepo
            ))
        } catch {
            fatalError("Failed to initialize repositories for BatchPledgeView: \(error)")
        }
    }
    
    // KEEP: body structure
    var body: some View {
        VStack(spacing: 0) {
            // MODIFY: globalPledgeSettingsBar will have its padding applied directly within its definition
            globalPledgeSettingsBar
            // MODIFY: pledgeColumnHeaders will have its padding applied directly within its definition
            pledgeColumnHeaders
            List {
                ForEach(Array(viewModel.rows.enumerated()), id: \.element.id) { index, _ in
                    pledgeRowView(row: $viewModel.rows[index])
                        .focused($focusedRowID, equals: viewModel.rows[index].id)
                    // MODIFY: List row insets to match BatchDonationView's default or explicit settings if any.
                    // BatchDonationView used .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    // Let's keep this consistent for now, assuming the padding inside pledgeRowView is adjusted.
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowSeparator(.visible)
                        .listRowBackground( index % 2 == 0 ? Color(.systemBackground) :  Color(.systemGray6).opacity(0.3) )
                }
            }
            .listStyle(.plain)
            // MODIFY: Match BatchDonationView's background and padding for the List container
            .background(Color(.systemBackground)) // Match BatchDonationView
            .clipShape(RoundedRectangle(cornerRadius: 8)) // Match BatchDonationView
            .padding(.horizontal, 16) // Match BatchDonationView
        }
        .navigationTitle("Batch Pledges")
        .navigationBarTitleDisplayMode(.inline)
        // KEEP: toolbar, sheets, alerts
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    if !viewModel.rows.contains(where: { $0.isValidDonor }) {
                        Button(action: { print("Back pressed") }) {
                            HStack(spacing: 5) { Image(systemName: "chevron.left"); Text("Back") }
                                .foregroundColor(.blue) // Match BatchDonationView
                        }
                    }
                    if viewModel.rows.contains(where: { $0.isValidDonor }) {
                        Button("Clear All", role: .destructive) {
                            viewModel.clearBatch()
                            focusedRowID = viewModel.rows.first?.id
                        }
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.rows.contains(where: { $0.isValidDonor }) {
                    Button("Save Pledges") {
                        Task {
                            saveResult = await viewModel.saveBatchPledges(selectedCampaignId: selectedCampaign?.id)
                            showingSaveSummary = true
                        }
                    }
                    .foregroundColor(.blue) // Match BatchDonationView
                    .disabled(viewModel.rows.allSatisfy { !$0.isValidDonor })
                }
            }
        }
        //        .sheet(isPresented: $showingDonorSearch) {
        //            MockDonorSearchView( // Assuming MockDonorSearchView is styled appropriately or is simple enough not to clash.
        //                                // If DonorSearchSelectionView from BatchDonationView is preferred, this would be a larger change.
        //                searchAction: { query in viewModel.searchMockDonors(query: query) },
        //                onDonorSelected: { selectedDonor in
        //                    if let rowID = currentRowIDForSearch {
        //                        Task { await viewModel.setDonorFromSearch(selectedDonor, for: rowID) }
        //                    }
        //                    showingDonorSearch = false
        //                    currentRowIDForSearch = nil
        //                }
        //            )
        //        }
        .sheet(isPresented: $showingDonorSearch) {
            DonorSearchSelectionView { selectedDonor in
                if let rowID = currentRowIDForSearch {
                    Task { await viewModel.setDonorFromSearch(selectedDonor, for: rowID) }
                }
                showingDonorSearch = false
                currentRowIDForSearch = nil
            }
            .environmentObject(donorObject)
        }
        .alert("Batch Pledges Saved", isPresented: $showingSaveSummary, presenting: saveResult) { result in
            Button("OK") {
                if result.failed == 0 && result.success > 0 { viewModel.clearBatch(); focusedRowID = viewModel.rows.first?.id }
                saveResult = nil
            }
        } message: { result in
            Text("Successfully saved: \(result.success)\nFailed: \(result.failed)\nTotal Pledged Amount: \(formatCurrency(result.totalAmount))")
        }
        .sheet(isPresented: $showingPrayerNoteSheet, onDismiss: {
            if let rowIndex = viewModel.rows.firstIndex(where: { $0.id == currentPrayerRowID }) {
                viewModel.rows[rowIndex].prayerNote = currentPrayerNote
                if currentPrayerNote.isEmpty { viewModel.rows[rowIndex].prayerNoteSW = false }
            }
        }) {
            if let donor = selectedDonorForPrayer { PrayerNoteSheet(donor: donor, prayerNote: $currentPrayerNote) }
            else { PrayerNoteSheet(donor: nil, prayerNote: $currentPrayerNote) }
        }
    }
    
    // MODIFY: globalPledgeSettingsBar styling to match BatchDonationView
    private var globalPledgeSettingsBar: some View {
        HStack(spacing: 20) { // Match BatchDonationView spacing
            HStack(spacing: 8) { // Match BatchDonationView inner spacing
                Text("Amount:")
                    .foregroundColor(.secondary) // Keep
                TextField("", value: $viewModel.globalPledgeAmount, format: .currency(code: "USD"))
                    .textFieldStyle(.roundedBorder) // Keep
                    .frame(width: 80) // Match BatchDonationView
            }
            HStack(spacing: 8) {
                Text("Campaign:")
                    .foregroundColor(.secondary)
                Menu {
                    Button("None") { selectedCampaign = nil }
                    ForEach(viewModel.getMockCampaigns()) { campaign in Button(campaign.name) { selectedCampaign = campaign } }
                } label: {
                    Text(selectedCampaign?.name ?? "None")
                        .foregroundColor(.blue) // Match BatchDonationView
                }
            }
            HStack(spacing: 8) {
                Text("Status:")
                    .foregroundColor(.secondary)
                Menu {
                    ForEach(PledgeStatus.allCases) { status in Button(status.displayName) { viewModel.globalPledgeStatus = status } }
                } label: {
                    Text(viewModel.globalPledgeStatus.displayName)
                        .foregroundColor(.blue) // Match BatchDonationView
                }
            }
            HStack(spacing: 8) {
                Text("Fulfill by:")
                    .foregroundColor(.secondary)
                DatePicker("", selection: $viewModel.globalExpectedFulfillmentDate, displayedComponents: .date)
                    .labelsHidden() // Keep
                    .frame(minWidth: 90) // Keep, or adjust if BatchDonationView has a different approach
            }
            // Removed "Confirm" toggle section
            
            Spacer() // Match BatchDonationView
        }
        .padding(.horizontal) // Match BatchDonationView
        .padding(.vertical, 8) // Match BatchDonationView
        .background(Color(.systemGray6)) // Match BatchDonationView
    }
    
    // MODIFY: pledgeColumnHeaders styling to match BatchDonationView
    private var pledgeColumnHeaders: some View {
        HStack { // This HStack itself will get an outer padding
            Text("Status").frame(width: 50)
            Text("Donor ID").frame(width: 70)
            Text("Name & Address").frame(maxWidth: .infinity, alignment: .leading)
            Text("Prayer").frame(width: 50)
            // Removed "Confirm" header
            Text("Pledge Status").frame(width: 110)
            Text("Fulfill By").frame(width: 90) // Keep width or adjust
            Text("Amount").frame(width: 70, alignment: .trailing)
            Text("Action").frame(width: 50)
        }
        .font(.caption.bold()) // Keep
        .foregroundColor(.secondary) // Keep
        .padding(.horizontal) // Inner padding
        .padding(.vertical, 8) // Match BatchDonationView vertical padding
        .background(
            Rectangle()
                .fill(Color(.systemGray6).opacity(0.7)) // Match BatchDonationView
                .shadow(color: .black.opacity(0.05), radius: 1, y: 1) // Match BatchDonationView
        )
        .padding(.horizontal) // Outer padding to match BatchDonationView's structure
    }
    
    // MODIFY: pledgeRowView styling to match batchRowView from BatchDonationView
    @ViewBuilder
    private func pledgeRowView(row: Binding<BatchPledgeViewModel.PledgeEntry>) -> some View {
        let r = row.wrappedValue
        HStack {
            Image(systemName: statusIcon(for: r.processStatus)).foregroundColor(statusColor(for: r.processStatus)).frame(width: 50, alignment: .center) // Keep
            
            TextField("ID", value: row.donorID, format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 70)
                .keyboardType(.numberPad)
                .disabled(r.isValidDonor)
                .foregroundColor(r.isValidDonor ? .gray : .primary) // Keep
                .background(r.isValidDonor ? Color(.systemGray6) : Color(.systemBackground)) // Match BatchDonationView
            
            Text(r.displayInfo.isEmpty && r.donorID == nil ? "Enter ID or Search" : r.displayInfo)
                .font(r.isValidDonor ? .body : .callout) // MODIFY: Match BatchDonationView fonts
                .foregroundColor(r.isValidDonor ? .primary : (r.displayInfo.contains("Error") || r.displayInfo.contains("not found") ? .red : .secondary)) // Keep
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2) // Keep
                .help(r.displayInfo)
            
            Toggle("", isOn: row.prayerNoteSW).labelsHidden().frame(width: 50, alignment: .center).toggleStyle(.button).disabled(!r.isValidDonor)
                .onChange(of: row.prayerNoteSW.wrappedValue) { oldValue, newValue in
                    if newValue {
                        currentPrayerRowID = r.id
                        //                        selectedDonorForPrayer = viewModel.getDonor(by: r.donorID)
                        //                        currentPrayerNote = r.prayerNote ?? ""
                        //                        showingPrayerNoteSheet = true
                        Task {
                            if let donorId = r.donorID {
                                selectedDonorForPrayer = try? await donorObject.getDonor(donorId)
                                currentPrayerNote = r.prayerNote ?? ""
                                showingPrayerNoteSheet = true
                            }
                        }
                    }
                }
            
            // Removed "Confirm" toggle
            
            Picker("", selection: row.pledgeStatusOverride) { ForEach(PledgeStatus.allCases) { status in Text(status.displayName).tag(status) } }
                .pickerStyle(.menu)
                .frame(width: 110) // Adjust width as needed
                .disabled(!r.isValidDonor)
            
            DatePicker("", selection: row.expectedFulfillmentDate, displayedComponents: .date)
                .labelsHidden()
                .frame(width: 90) // Adjust width as needed
                .disabled(!r.isValidDonor)
            
            TextField("Amount", value: row.pledgeOverride, format: .currency(code: "USD"))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .frame(width: 70)
                .foregroundColor(r.hasPledgeOverride ? .blue : .primary) // Keep
                .disabled(!r.isValidDonor)
            
            actionButton(row: row).frame(width: 50, alignment: .center) // Keep
        }
        .padding(.vertical, 8) // MODIFY: Match BatchDonationView padding
        .overlay(
            RoundedRectangle(cornerRadius: 4) // Keep overlay logic
                .stroke(
                    r.isValidDonor ? Color.clear :
                        (r.displayInfo.contains("Error") || r.displayInfo.contains("not found") ?
                         Color.red.opacity(0.3) : Color.gray.opacity(0.3)),
                    lineWidth: 1
                )
                .padding(.horizontal, 8) // Keep
        )
    }
    
    // KEEP: actionButton and helper functions (statusIcon, statusColor, formatCurrency, isFailureStatus)
    @ViewBuilder
    private func actionButton(row: Binding<BatchPledgeViewModel.PledgeEntry>) -> some View {
        let r = row.wrappedValue
        if r.isValidDonor {
            Button { viewModel.rows.removeAll { $0.id == r.id } } label: { Image(systemName: "trash").foregroundColor(.red) }.buttonStyle(PlainButtonStyle())
        } else {
            Menu {
                Button { 
                    Task { 
                        if let donorID = r.donorID {
                            await viewModel.findDonor(for: r.id) 
                        }
                    } 
                } label: { 
                    Label("Find by ID", systemImage: "number") 
                }
                .disabled(r.donorID == nil)
                Button { currentRowIDForSearch = r.id; showingDonorSearch = true } label: { Label("Search Donor", systemImage: "magnifyingglass") }
            } label: { Image(systemName: "ellipsis.circle").foregroundColor(.blue).imageScale(.large) }.buttonStyle(PlainButtonStyle()).disabled(isFailureStatus(r.processStatus)) // Match BatchDonationView's imageScale
        }
    }
    
    private func statusIcon(for status: BatchPledgeViewModel.RowProcessStatus) -> String {
        switch status { case .none: return "circle"; case .success: return "checkmark.circle.fill"; case .failure: return "xmark.octagon.fill" }
    }
    private func statusColor(for status: BatchPledgeViewModel.RowProcessStatus) -> Color {
        switch status { case .none: return .gray.opacity(0.5); case .success: return .green; case .failure: return .red }
    }
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter(); formatter.numberStyle = .currency; formatter.currencyCode = "USD"; return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    private func isFailureStatus(_ status: BatchPledgeViewModel.RowProcessStatus) -> Bool {
        if case .failure = status { return true }; return false
    }
}

// KEEP: MockDonorSearchView
struct MockDonorSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var searchResults: [Donor] = []
    var searchAction: (String) -> [Donor]
    var onDonorSelected: (Donor) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search donor name...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: searchText) { oldValue, newValue in searchResults = searchAction(newValue) }
                    if !searchText.isEmpty { Button { searchText = ""; searchResults = searchAction("") } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.gray) } }
                }.padding()
                List(searchResults) { donor in
                    VStack(alignment: .leading) { Text(donor.fullName); Text(donor.address ?? "").font(.caption).foregroundColor(.gray) } // Mock view styling can be separate
                        .contentShape(Rectangle()).onTapGesture { onDonorSelected(donor) }
                }
            }
            .navigationTitle("Search Donor (Mock)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}
