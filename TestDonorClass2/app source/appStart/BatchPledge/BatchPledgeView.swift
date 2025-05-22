import SwiftUI

// BatchPledgeView (and its subviews like MockDonorSearchView)
// from the previous response should be pasted here.
// Ensure all helper functions (statusIcon, statusColor, formatCurrency, isFailureStatus)
// are also included within BatchPledgeView.

struct BatchPledgeView: View {
    @EnvironmentObject var campaignObject: CampaignObjectClass
    // KEEP: EnvironmentObject for DonorObjectClass
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
            let donorRepo = try DonorRepository()
            let pledgeRepo = try PledgeRepository()
            _viewModel = StateObject(wrappedValue: BatchPledgeViewModel(
                repository: donorRepo,
                pledgeRepository: pledgeRepo
            ))
        } catch {
            fatalError("Failed to initialize repositories for BatchPledgeView: \(error)")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            globalPledgeSettingsBar
            pledgeColumnHeaders
            List {
                ForEach(Array(viewModel.rows.enumerated()), id: \.element.id) { index, _ in
                    pledgeRowView(row: $viewModel.rows[index])
                        .focused($focusedRowID, equals: viewModel.rows[index].id)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowSeparator(.visible)
                        .listRowBackground( index % 2 == 0 ? Color(.systemBackground) :  Color(.systemGray6).opacity(0.3) )
                }
            }
            .listStyle(.plain)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 16)
        }
        .navigationTitle("Batch Pledges")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    if !viewModel.rows.contains(where: { $0.isValidDonor }) {
                        Button(action: { print("Back pressed") }) {
                            HStack(spacing: 5) { Image(systemName: "chevron.left"); Text("Back") }
                                .foregroundColor(.blue)
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
                    .foregroundColor(.blue)
                    .disabled(viewModel.rows.allSatisfy { !$0.isValidDonor })
                }
            }
        }
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
        .task {
            await campaignObject.loadCampaigns()
        }
    }
    
    private var globalPledgeSettingsBar: some View {
        HStack(spacing: 20) {
            HStack(spacing: 8) {
                Text("Amount:")
                    .foregroundColor(.secondary)
                TextField("", value: $viewModel.globalPledgeAmount, format: .currency(code: "USD"))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }
            HStack(spacing: 8) {
                Text("Campaign:")
                    .foregroundColor(.secondary)
                Menu {
                    Button("None") { selectedCampaign = nil }
                    ForEach(campaignObject.campaigns.filter { $0.status == .active }) { campaign in
                        Button(campaign.name) { selectedCampaign = campaign }
                    }
                } label: {
                    Text(selectedCampaign?.name ?? "None")
                        .foregroundColor(.blue)
                }
            }
            HStack(spacing: 8) {
                Text("Status:")
                    .foregroundColor(.secondary)
                Menu {
                    ForEach(PledgeStatus.allCases) { status in Button(status.displayName) { viewModel.globalPledgeStatus = status } }
                } label: {
                    Text(viewModel.globalPledgeStatus.displayName)
                        .foregroundColor(.blue)
                }
            }
            HStack(spacing: 8) {
                Text("Fulfill by:")
                    .foregroundColor(.secondary)
                DatePicker("", selection: $viewModel.globalExpectedFulfillmentDate, displayedComponents: .date)
                    .labelsHidden()
                    .frame(minWidth: 90)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private var pledgeColumnHeaders: some View {
        HStack {
            Text("Status").frame(width: 50)
            Text("Donor ID").frame(width: 70)
            Text("Name & Address").frame(maxWidth: .infinity, alignment: .leading)
            Text("Prayer").frame(width: 50)
            Text("Pledge Status").frame(width: 110)
            Text("Fulfill By").frame(width: 90)
            Text("Amount").frame(width: 70, alignment: .trailing)
            Text("Action").frame(width: 50)
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
    
    @ViewBuilder
    private func pledgeRowView(row: Binding<BatchPledgeViewModel.PledgeEntry>) -> some View {
        let r = row.wrappedValue
        HStack {
            Image(systemName: statusIcon(for: r.processStatus)).foregroundColor(statusColor(for: r.processStatus)).frame(width: 50, alignment: .center)
            
            TextField("ID", value: row.donorID, format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 70)
                .keyboardType(.numberPad)
                .disabled(r.isValidDonor)
                .foregroundColor(r.isValidDonor ? .gray : .primary)
                .background(r.isValidDonor ? Color(.systemGray6) : Color(.systemBackground))
            
            Text(r.displayInfo.isEmpty && r.donorID == nil ? "Enter ID or Search" : r.displayInfo)
                .font(r.isValidDonor ? .body : .callout)
                .foregroundColor(r.isValidDonor ? .primary : (r.displayInfo.contains("Error") || r.displayInfo.contains("not found") ? .red : .secondary))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
                .help(r.displayInfo)
            
            Toggle("", isOn: row.prayerNoteSW).labelsHidden().frame(width: 50, alignment: .center).toggleStyle(.button).disabled(!r.isValidDonor)
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
            
            Picker("", selection: row.pledgeStatusOverride) { ForEach(PledgeStatus.allCases) { status in Text(status.displayName).tag(status) } }
                .pickerStyle(.menu)
                .frame(width: 110)
                .disabled(!r.isValidDonor)
            
            DatePicker("", selection: row.expectedFulfillmentDate, displayedComponents: .date)
                .labelsHidden()
                .frame(width: 90)
                .disabled(!r.isValidDonor)
            
            TextField("Amount", value: row.pledgeOverride, format: .currency(code: "USD"))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .frame(width: 70)
                .foregroundColor(r.hasPledgeOverride ? .blue : .primary)
                .disabled(!r.isValidDonor)
            
            actionButton(row: row).frame(width: 50, alignment: .center)
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
            } label: { Image(systemName: "ellipsis.circle").foregroundColor(.blue).imageScale(.large) }.buttonStyle(PlainButtonStyle()).disabled(isFailureStatus(r.processStatus))
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
                    VStack(alignment: .leading) { Text(donor.fullName); Text(donor.address ?? "").font(.caption).foregroundColor(.gray) }
                        .contentShape(Rectangle()).onTapGesture { onDonorSelected(donor) }
                }
            }
            .navigationTitle("Search Donor (Mock)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}
