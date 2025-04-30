//
//  BatchDonationView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/30/25.
//

import SwiftUI

// Contents of ./screens/BatchDonations/BatchDonationView.swift
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
    @FocusState private var focusedRowID: UUID?

    @State private var showingSaveSummary = false
    @State private var saveResult: (success: Int, failed: Int, totalAmount: Double)? = nil
    
    
    @State private var showingPrayerNoteSheet = false
    @State private var selectedDonorForPrayer: Donor? = nil
    @State private var currentPrayerNote: String = ""
    @State private var currentPrayerRowID: UUID? = nil

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

    // Add computed properties for first row access
    private var firstRow: BatchDonationViewModel.RowEntry? {
        viewModel.rows.first
    }
    
    private var firstRowIsValid: Bool {
        guard let row = firstRow else { return false }
        return row.isValidDonor && row.donorID != nil
    }
    
    // Example validation method
    private func validateFirstRow() -> (isValid: Bool, message: String?) {
        guard let row = firstRow else {
            return (false, "No rows available")
        }
        
        // Check donor ID
        guard let donorId = row.donorID else {
            return (false, "No donor ID specified")
        }
        
        // Check amount
        if row.donationOverride <= 0 {
            return (false, "Invalid amount")
        }
        
        // All checks passed
        return (true, nil)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Global Settings Bar

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
                            ForEach(campaignObject.campaigns) { campaign in
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
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))

            // Column Headers
            HStack {
                Text("Status")
                    .frame(width: 50)
                Text("Donor ID")
                    .frame(width: 70)
                Text("Name & Address")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Receipt")
                    .frame(width: 60)
                Text("Type")
                    .frame(width: 90)
                Text("Pay Status")
                    .frame(width: 90)
                Text("Amount")
                    .frame(width: 70, alignment: .trailing)
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

            // Donation Rows List
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
            
            // Example button to check first row
            Button("Check First Row") {
                if let row = firstRow {
                    print("Donor ID: \(row.donorID ?? 0)")
                    print("Amount: \(row.donationOverride)")
                    print("Type: \(row.donationTypeOverride)")
                    print("Status: \(row.paymentStatusOverride)")
                    print("Is Valid: \(row.isValidDonor)")
                    
                    // Validate the row
                    let validation = validateFirstRow()
                    if !validation.isValid {
                        print("Validation failed: \(validation.message ?? "Unknown error")")
                    }
                }
            }
          /*
            // Example of conditional rendering based on first row state
            if let row = firstRow, row.isValidDonor {
                Text("Valid donor: ID \(row.donorID ?? 0)")
                    .foregroundColor(.green)
            }
        */
        .navigationTitle("Batch Donations")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
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
                                viewModel.clearBatch()
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
        .sheet(isPresented: $showingDonorSearch) {
            DonorSearchSelectionView { selectedDonor in
                if let rowID = currentRowID {
                    Task {
                        await viewModel.setDonorFromSearch(selectedDonor, for: rowID)
                        currentRowID = nil
                    }
                } else {
                      print("Error: currentRowID was nil when donor search returned.")
                 }
             }
             .environmentObject(donorObject)
         }
         .alert("Batch Save Summary", isPresented: $showingSaveSummary, presenting: saveResult) { result in
              Button("OK") {
                  if result.failed == 0 && result.success > 0 {
                      viewModel.clearBatch()
//                      viewModel.addRow()
//                      focusedRowID = viewModel.rows.last?.id
                  }
                  saveResult = nil
              }
          } message: { result in
              Text("Successfully saved: \(result.success)\nFailed: \(result.failed)\nTotal Amount: \(formatCurrency(result.totalAmount))")
          }
        
        // Add the sheet:
        .sheet(isPresented: $showingPrayerNoteSheet, onDismiss: {
            // When dismissed, update the note in the model
            if let rowIndex = viewModel.rows.firstIndex(where: { $0.id == currentPrayerRowID }) {
                viewModel.rows[rowIndex].prayerNote = currentPrayerNote
                // If the note is empty, turn off the toggle
                if currentPrayerNote.isEmpty {
                    viewModel.rows[rowIndex].prayerNoteSW = false
                }
            }
        }) {
            // Pass the entire donor object
            if let donor = selectedDonorForPrayer {
                PrayerNoteSheet(
                    donor: donor,
                    prayerNote: $currentPrayerNote
                )
            } else {
                // Fallback if donor isn't loaded yet
                PrayerNoteSheet(
                    donor: nil,
                    prayerNote: $currentPrayerNote
                )
            }
        }
        
        .task {
            await campaignObject.loadCampaigns()
        }
    }

    // Extracted Row View Builder
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

            // Donor Info Display
            Text(r.displayInfo.isEmpty && r.donorID == nil ? "Enter ID or Search" : r.displayInfo)
                .font(r.isValidDonor ? .body : .callout)
                .foregroundColor(r.isValidDonor ? .primary : (r.displayInfo.contains("Error") || r.displayInfo.contains("not found") ? .red : .secondary))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
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
                .frame(width: 70)
                // **** FIX 2: Remove .wrappedValue ****
                .foregroundColor(r.hasDonationOverride ? .blue : .primary) // Use 'r' here
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
            Menu {
                Button {
                    Task { await viewModel.findDonor(for: r.id) }
                } label: {
                    Label("Find by ID", systemImage: "number")
                }
                .disabled(r.donorID == nil)

                Button {
                    currentRowID = r.id
                    showingDonorSearch = true
                } label: {
                    Label("Search Donor", systemImage: "magnifyingglass")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.blue)
                    .imageScale(.large)
            }
            .buttonStyle(PlainButtonStyle())
            // **** FIX 3: Use helper function to check status case ****
            .disabled(isFailureStatus(r.processStatus)) // Maybe disable if failed?
        }
    }

    // ... (statusIcon, statusColor, formatCurrency helpers remain the same) ...
      private func statusIcon(for status: BatchDonationViewModel.RowProcessStatus) -> String { /* ... */
         switch status {
         case .none: return "circle"
         case .success: return "checkmark.circle.fill"
         case .failure: return "xmark.octagon.fill"
         }
    }
      private func statusColor(for status: BatchDonationViewModel.RowProcessStatus) -> Color { /* ... */
         switch status {
         case .none: return .gray.opacity(0.5)
         case .success: return .green
         case .failure: return .red
         }
    }
      private func formatCurrency(_ amount: Double) -> String { /* ... */
          let formatter = NumberFormatter()
          formatter.numberStyle = .currency
          formatter.currencyCode = "USD"
          return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
      }

    // **** FIX 3 (Add Helper Function): Add this inside BatchDonationView ****
    private func isFailureStatus(_ status: BatchDonationViewModel.RowProcessStatus) -> Bool {
        if case .failure = status {
            return true
        }
        return false
    }
    // **** End FIX 3 ****
}

// Example extension for additional row validation
extension BatchDonationViewModel.RowEntry {
    var isAmountValid: Bool {
        return donationOverride > 0
    }
    
    var isDonorValid: Bool {
        return isValidDonor && donorID != nil
    }
    
    var isReadyToProcess: Bool {
        return isAmountValid && isDonorValid
    }
}

//  MARK: - Toolbar Builder
extension BatchDonationView {
    @ToolbarContentBuilder
    func SaveCancelToolBar() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Clear All") {
                viewModel.clearBatch() // Corrected typo if needed
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
