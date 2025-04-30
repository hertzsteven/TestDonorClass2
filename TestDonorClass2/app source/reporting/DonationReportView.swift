//
//  DonationReportView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 3/30/25.
//

// Contents of ./reporting/DonationReportView.swift

import SwiftUI

struct DonationReportView: View {
    // Use @StateObject for view-specific view models
    @StateObject private var viewModel: DonationReportViewModel

    @State private var showingDonorSearchView = false
    @EnvironmentObject var donorObject: DonorObjectClass // Still needed for DonorSearchSelectionView

    // Custom Initializer
    init() {
        // Create the repository instances HERE.
        // Use try! because we assume DatabaseManager initialization succeeded
        // (as it would have caused a fatalError otherwise).
        // If getDbPool were to fail later unexpectedly, this would crash,
        // indicating a severe problem.
        do {
            let donationRepo = try! DonationRepository(/* optionally pass specific dbPool if needed */)
            let donorRepo = try! DonorRepository(/* ... */)
            let campaignRepo = try! CampaignRepository(/* ... */)

            // Initialize the StateObject with the required dependencies
            _viewModel = StateObject(wrappedValue: DonationReportViewModel(
                donationRepository: donationRepo,
                donorRepository: donorRepo,
                campaignRepository: campaignRepo
            ))
        } catch {
             // This catch block is technically reachable if you remove try!
             // but with try!, an error here leads to a crash before the catch.
             // If you used try? instead, you'd handle nil repositories here.
             fatalError("Failed to initialize repositories for DonationReportView: \(error)")
        }
    }

    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                // Left Column - Filters and Summary
                VStack(alignment: .leading, spacing: 0) {
                    // --- Filter Form ---
                    Form {
                        Section("Filters") {
                            // Time Frame
                            Picker("Time Frame", selection: $viewModel.selectedTimeFrame) {
                                ForEach(TimeFrame.allCases) { frame in
                                    Text(frame.rawValue).tag(frame)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.vertical, 8)

                            // Campaign
                            Picker("Campaign", selection: $viewModel.selectedCampaignId) {
                                Text("All Campaigns").tag(Int?.none)
                                ForEach(viewModel.availableCampaigns) { campaign in
                                    Text(campaign.name).tag(campaign.id as Int?)
                                }
                            }
                            .pickerStyle(.menu)

                            // Donor
                            HStack {
                                Text("Donor:")
                                Spacer()
                                Button {
                                    showingDonorSearchView = true
                                } label: {
                                    HStack {
                                        Text(viewModel.selectedDonorName)
                                            .foregroundColor(viewModel.selectedDonorId == nil ? .gray : .accentColor)
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showingDonorSearchView = true
                            }

                            // Prayer Notes Filter
                            Toggle("Show Prayer Notes Only", isOn: $viewModel.showOnlyPrayerNotes)
                                .onChange(of: viewModel.showOnlyPrayerNotes) { _ in
                                    Task { await viewModel.updateReport() }
                                }
                        
                        
                            // Amount Range
                            HStack {
                                Text("Amount:")
                                Spacer()
                                TextField("Min", text: $viewModel.minAmountString)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                Text("-")
                                TextField("Max", text: $viewModel.maxAmountString)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                            }
                        }
                    }
                    
                    Divider()

                    // --- Summary Section ---
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SUMMARY")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top)

                        Grid(alignment: .leading, horizontalSpacing: 20) {
                            GridRow {
                                Text("Total Donations:")
                                    .foregroundColor(.secondary)
                                Text(formatCurrency(viewModel.totalFilteredAmount))
                                    .bold()
                            }
                            GridRow {
                                Text("Average Donation:")
                                    .foregroundColor(.secondary)
                                Text(formatCurrency(viewModel.averageFilteredAmount))
                            }
                            GridRow {
                                Text("Number of Donations:")
                                    .foregroundColor(.secondary)
                                Text("\(viewModel.filteredCount)")
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                    .background(Color(.systemBackground))
                }
                .frame(width: 400) // Fixed width for left column
                
                // Vertical Divider
                Divider()
                
                // Right Column - Results List
                VStack(alignment: .leading) {
                    Text("Matching Donations (\(viewModel.filteredCount))")
                        .font(.headline)
                        .padding()
                    
                    if viewModel.isLoading {
                        ProgressView("Loading Report...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.isFilteringInProgress {
                        Color.clear
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay(
                                VStack {
                                    ProgressView()
                                    Text("Updating Results...")
                                        .foregroundColor(.secondary)
                                        .padding(.top, 8)
                                }
                            )
                    } else if let errorMsg = viewModel.errorMessage {
                        // Error state
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                            Text("Error Loading Report")
                                .font(.headline)
                            Text(errorMsg)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task { await viewModel.loadSupportingData() }
                            }
                            .buttonStyle(.bordered)
                            .padding(.top)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.filteredReportItems.isEmpty {
                        Text("No donations match the selected filters.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(viewModel.filteredReportItems) { item in
                                DonationReportRow(item: item)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Donation Report")
            .sheet(isPresented: $showingDonorSearchView) {
                DonorSearchSelectionView { selectedDonor in
                    viewModel.donorSelected(selectedDonor)
                }
                .environmentObject(donorObject)
            }
        }
        .navigationViewStyle(.stack)
    }

    // Helper function to format currency (Unchanged)
     private func formatCurrency(_ amount: Double) -> String {
         // Use the static formatter from the ViewModel
         return DonationReportViewModel.currencyFormatter.string(for: amount) ?? "$0.00"
     }

     // Helper to hide keyboard (Unchanged)
     private func hideKeyboard() {
         #if canImport(UIKit)
         UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
         #endif
     }
}

// --- Row View for the Report List (Unchanged) ---
struct DonationReportRow: View {
    let item: DonationReportItem
    // ADD: State property for disclosure group
    @State private var isExpanded = false


    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.donorName).font(.headline)
                Text(item.campaignName).font(.subheadline).foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(formatCurrency(item.amount))
                    .font(.headline)
                    .foregroundColor(.green) // Or another appropriate color
                Text(item.donationDate, formatter: DonationReportViewModel.dateFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
                // Add prayer note indicator
//                if item.hasPrayerNote {
//                    Image(systemName: "person.fill.questionmark")
//                        .foregroundColor(.blue)
//                        .help("Has prayer request")
//                }
//                // In your DonationReportRow

                if item.hasPrayerNote {
                    DisclosureGroup {
                        if let note = item.prayerNote {
                            Text(note)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    label: {
                        HStack {
                            Spacer()
                            Text("Notes")
                                .foregroundColor(.blue)
                                .help("Prayer request: click to expand")
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 4) // Add slight vertical padding to rows
        }
    }

//    // You'll need a function to get the full donation from an ID:
//    private func getFullDonation(id: Int) -> Donation {
//        // Access your donation repository to get the full donation
//        // This is a placeholder - you'll need to implement actual data access
//        return donationRepository.getOne(id) ?? Donation(amount: 0, donationType: .cash)
//    }
     // Use the static formatter from the ViewModel
     private func formatCurrency(_ amount: Double) -> String {
         return DonationReportViewModel.currencyFormatter.string(for: amount) ?? "$0.00"
     }
}


// --- Preview ---
struct DonationReportView_Previews: PreviewProvider {
    static var previews: some View {
        // Use try! for preview initialization, accepting potential crash
        // if DB setup fails during preview build.
        let previewDonorObject = try! DonorObjectClass()
        // Create other objects similarly if needed
        // let previewCampaignObject = try! CampaignObjectClass()
        // let previewDonationObject = try! DonationObjectClass()
        
        DonationReportView()
            .environmentObject(previewDonorObject) // Provide the initialized object
                                                   // Add other necessary environment objects
                                                   // .environmentObject(previewCampaignObject)
                                                   // .environmentObject(previewDonationObject)
    }
}
