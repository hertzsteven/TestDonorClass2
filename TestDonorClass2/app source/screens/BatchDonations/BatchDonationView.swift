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


    // If you want your focus to jump from row to row:
    @FocusState private var focusedRowID: UUID?
    
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Global donation amount across all rows
            HStack {
                CampaignPickerView(selectedCampaign: $selectedCampaign)
                Text("Global Amount:")
                TextField("Enter global donation",
                          value: $viewModel.globalDonation, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 100)
               
            }
            .padding()
            
            // Optional column headers
            HStack {
                Text("Code")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Donor Information")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Donation")
                    .frame(width: 80, alignment: .leading)
                Text("Find")
                    .frame(width: 50, alignment: .center)
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
                            .frame(maxWidth: .infinity)
                            .focused($focusedRowID, equals: row.id)

                        // Donor Information text
                        Text(row.displayInfo)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(row.isValidDonor ? .primary : .red)

                        // Donation text field
                        TextField("Amount", value: $row.donationOverride, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .disabled(!row.isValidDonor)

                        // Find button
                        Button {
                            Task {
                                await viewModel.findDonor(for: row.id)
                                // Move focus to the row ID we just appended
                                focusedRowID = viewModel.focusedRowID
                            }
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                        .frame(width: 50)
                        .disabled(row.donorID == nil)
                    }
                }
            }
            .onChange(of: viewModel.focusedRowID) { newID in
                focusedRowID = newID
            }

            // Optionally, a button to finalize & save all rows into the donation table:
            HStack {
                Spacer()
                Button("advanced Batch") {
                    for row in viewModel.rows  where row.donorID != nil {
                           let donorIDString = row.donorID.map(String.init) ?? "(none)"
                        let donationAmount = (row.donationOverride == 0.0)
                               ? viewModel.globalDonation
                               : row.donationOverride
                           
                           print("DonorID: \(donorIDString), Amount: \(donationAmount)")
                       }
                }
                Button("Save Batch") {
                    saveBatchDonations()
                }
            }
                .padding(.bottom)
//            }
        }
        .toolbar {
            SaveCancelToolBar()
        }
        
        .onAppear {
            Task {
                await campaignObject.loadCampaigns()
            }
        }

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
            let currentRow = viewModel.rows[i]
            let donorIDString = currentRow.donorID.map(String.init) ?? "(none)"
            
                // If the row's override is blank, use the globalDonation
            let donationAmount = (currentRow.donationOverride == 0.0)
            ? viewModel.globalDonation
            : currentRow.donationOverride
            
            let campaignID = selectedCampaign?.id ?? nil
            let donorID = viewModel.rows[i].donorID
            print("DonorID: \(donorIDString), Amount: \(donationAmount)")
            
            Task {
                let donation = Donation(donorId:        donorID,
                                        campaignId:     campaignID,
                                        amount:         donationAmount,
                                        donationType:   .check)
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
