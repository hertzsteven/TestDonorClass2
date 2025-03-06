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

    @StateObject private var viewModel = BatchDonationViewModel()

    @State private var selectedCampaign: Campaign?
    @State private var selectedDonationType: DonationType = .check
    @State private var selectedPaymentStatus: PaymentStatus = .completed

    // 1. First, add these state variables to your BatchDonationView
    @State private var showingDonorSearch = false
    @State private var currentRowID: UUID? = nil


    // If you want your focus to jump from row to row:
    @FocusState private var focusedRowID: UUID?
    
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Global donation amount across all rows
            HStack {
                Text("Amount:")
                    .padding(.leading, 16)
                TextField("Enter Donation",
                          value: $viewModel.globalDonation, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 100)
                    .padding(.trailing, 12)
                
                Text("Campaign")
                    .padding(.trailing, -10)
                Picker("Campaign", selection: $selectedCampaign) {
                    Text("None").tag(nil as Campaign?)
                        //
                    ForEach(campaignObject.campaigns.filter { $0.id ?? 100 > 99 }) { campaign in
                            //                    ForEach(campaignObject.campaigns) { campaign in
                        Text(campaign.name).tag(campaign  as Campaign?)
                    }
                }

//                CampaignPickerView(selectedCampaign: $selectedCampaign)
//                    .padding(.leading, 16)
                
                // Add Donation Type Picker
                Picker("Type", selection: $viewModel.globalDonationType) {
                    ForEach(DonationType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .frame(width: 100)
                
                // Add Payment Status Picker
                Picker("Status", selection: $viewModel.globalPaymentStatus) {
                    ForEach([PaymentStatus.completed, .pending, .failed], id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .frame(width: 180)

            }
            
            
            // Optional column headers
            HStack {
                Text("Donor ID")
//                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                Text("Name and Address")
                    .frame(width: 570, alignment: .leading)
                Text("Receipt")
                    .frame(width: 100, alignment: .leading)
                Text("Type")
                    .frame(width: 95
                           , alignment: .leading)
                Text("Status")
                Spacer()
                Text("Amount")
                    .frame(width: 70, alignment: .leading)
                Text("Action")
                    .frame(width: 80, alignment: .center)
            }
            .font(.headline)
            .padding(.horizontal)

            // The list of rows
            List {
                ForEach($viewModel.rows) { $row in
                    HStack {
                        switch row.processStatus {
                        case .none:
                            EmptyView()  // no icon yet
                        case .success:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        case .failure:
                            Image(systemName: "xmark.octagon.fill")
                                .foregroundColor(.red)
                        }
                        
                        // Donor Code (ID) text field
                        TextField("Donor ID", value: $row.donorID, formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .focused($focusedRowID, equals: row.id)

                        // Donor Information text
                        Text(row.displayInfo)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(row.isValidDonor ? .primary : .red)
                        
                        // Add Donation Type Override picker - only show when donor is valid
                        if row.isValidDonor {
                            
                            Toggle("", isOn: $row.printReceipt)
                                .labelsHidden()
                                .frame(width: 50)
                            
                            Picker("", selection: $row.donationTypeOverride) {
                                ForEach(DonationType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .frame(width: 120)
                            
                            // Add Payment Status Override picker - only show when donor is valid
                            Picker("", selection: $row.paymentStatusOverride) {
                                ForEach([PaymentStatus.completed, .pending, .failed], id: \.self) { status in
                                    Text(status.rawValue).tag(status)
                                }
                            }
                            .frame(width: 140)
                        }
                        
                        // Donation text field
                        TextField("Amount", value: $row.donationOverride, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .disabled(!row.isValidDonor)

                        // Replace the Find button with conditional button
                        if row.isValidDonor {
                            Button {
                                viewModel.rows.removeAll(where: { $0.id == row.id })
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .frame(width: 50)
                        } else {
                            
                            // Improved menu implementation that disables the menu when appropriate
                            Menu {
                                // Option 1: Search by ID (existing functionality)
                                Button {
                                    Task {
                                        await viewModel.findDonor(for: row.id)
                                        focusedRowID = viewModel.focusedRowID
                                    }
                                } label: {
                                    Label("Find by ID", systemImage: "number")
                                }
                                .disabled(row.donorID == nil)
                                
                                // Option 2: Search by name/address
                                Button {
                                    currentRowID = row.id
                                    showingDonorSearch = true
                                } label: {
                                    Label("Search by Name", systemImage: "magnifyingglass")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundColor(.blue)
                            }
                            .frame(width: 50)
                            // Disable the entire menu if we're in an invalid state
                            .disabled(row.id == nil)
                            
//                            Button {
//                                Task {
//                                    await viewModel.findDonor(for: row.id)
//                                    // Move focus to the row ID we just appended
//                                    focusedRowID = viewModel.focusedRowID
//                                }
//                            } label: {
//                                Image(systemName: "magnifyingglass")
//                            }
//                            .frame(width: 50)
//                            .disabled(row.donorID == nil)
                        }
                    }
                }
            }
            .onChange(of: viewModel.focusedRowID) { newID in
                focusedRowID = newID
            }
        }
        .toolbar {
            SaveCancelToolBar()
        }
        
        .onAppear {
            Task {
                await campaignObject.loadCampaigns()
            }
        }

        .sheet(isPresented: $showingDonorSearch, onDismiss: {
            // Clear the currentRowID when the sheet is dismissed
            currentRowID = nil
        }) {
            DonorSearchSelectionView { selectedDonor in
                if let rowID = currentRowID {
                    Task {
                        await viewModel.setDonorFromSearch(selectedDonor, for: rowID)
                    }
                }
            }
            .environmentObject(donorObject)
        }
//        .sheet(isPresented: $showingDonorSearch) {
//            if let rowID = currentRowID {
//                DonorSearchSelectionView { selectedDonor in
//                    Task {
//                        await viewModel.setDonorFromSearch(selectedDonor, for: rowID)
//                    }
//                }
//                .environmentObject(donorObject)
//            }
//        }
//        .padding(.horizontal)
            // Optional: load donors or do any setup
//            .task {
//                // If you want to ensure donors are loaded (or do other DB tasks)
//                // you can call:
//                // try? await donorObject.loadDonors()
//            }
        .navigationTitle("Batch Donations")
    }
    
    
}

extension BatchDonationView {
    fileprivate func saveBatchDonations() {
        
        guard !viewModel.rows.isEmpty else {
            return
        }
        
        var successfulDonationsCount    = 0
        var totalDonationAmount: Double = 0
        var failedDonationsCount        = 0
        
        for i in viewModel.rows.indices where viewModel.rows[i].donorID != nil {
            print("Processing row \(i)")
            let currentRow = viewModel.rows[i]
            let donorIDString = currentRow.donorID.map(String.init) ?? "(none)"
            
                // If the row's override is blank, use the globalDonation
            let donationAmount = (currentRow.donationOverride == 0.0)
            ? viewModel.globalDonation
            : currentRow.donationOverride
            
            let campaignID = selectedCampaign?.id ?? nil
            let donorID = viewModel.rows[i].donorID
            let paymentStatus = viewModel.rows[i].paymentStatusOverride 
            let donationType = viewModel.rows[i].donationTypeOverride
            let printReceipt = viewModel.rows[i].printReceipt
            
            print("DonorID: \(donorIDString), Amount: \(donationAmount)")
            
            Task {
                let donation = Donation(
                    donorId: donorID,
                    campaignId: campaignID,
                    amount: donationAmount,
                    donationType: donationType,
                    paymentStatus: paymentStatus,
                    requestPrintedReceipt: printReceipt
                )
                do {
                    try await viewModel.addDonation(donation)
                    viewModel.rows[i].processStatus = .success
                    successfulDonationsCount += 1
                    totalDonationAmount += donationAmount
                } catch {
                    print("Error adding donation: \(error)")
                    failedDonationsCount += 1
                    viewModel.rows[i].processStatus = .failure(message: error.localizedDescription)
                }
            }
        }
        print("Successful Donations: \(successfulDonationsCount)")
        print("Total Donation Amount: \(totalDonationAmount)")
        print("-------------------------")
        print("failed: \(failedDonationsCount)")
    }
}

    //  MARK: -  funcs that build tool bar
    extension BatchDonationView {
        @ToolbarContentBuilder
        func SaveCancelToolBar() -> some ToolbarContent {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    viewModel.cleearBatch()
//                    presentationMode.wrappedValue.dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveBatchDonations()
                }
//                .disabled(!isValidAmount)
            }
        }
    }


    // Your imports remain the same

    // All previous code remains the same

    // Replace the existing preview with this one
    #Preview {
        let donorObject = DonorObjectClass()
         let campaignObject = CampaignObjectClass()
         let donationObject = DonationObjectClass()
         
         // Initialize objects with any required setup
         // Add any necessary default data here if needed
         
         return NavigationStack {
             BatchDonationView()
                 .environmentObject(donorObject)
                 .environmentObject(campaignObject)
                 .environmentObject(donationObject)
         }

    }

    // End of file
    // End of file
