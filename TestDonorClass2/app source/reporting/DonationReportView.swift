//
//  DonationReportView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 3/30/25.
//

import SwiftUI

struct DonationReportView: View {
    @StateObject private var viewModel = DonationReportViewModel()
    @State private var showingDonorSearchView = false
    @EnvironmentObject var donorObject: DonorObjectClass

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // --- Filter Form ---
                Form {
                    Section("Filters") {
                        // ... Picker and Amount fields as before ...
                        Picker("Time Frame", selection: $viewModel.selectedTimeFrame) {
                             ForEach(TimeFrame.allCases) { frame in
                                 Text(frame.rawValue).tag(frame)
                             }
                         }
                        .pickerStyle(.menu)

                         Picker("Campaign", selection: $viewModel.selectedCampaignId) {
                             Text("All Campaigns").tag(Int?.none)
                             ForEach(viewModel.availableCampaigns) { campaign in
                                 Text(campaign.name).tag(campaign.id as Int?)
                             }
                         }
                         .pickerStyle(.menu)

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

                         HStack {
                             Text("Amount:")
                             Spacer()
                             TextField("Min", text: $viewModel.minAmountString)
                                 .keyboardType(.decimalPad)
                                 .frame(width: 100)
                                 .textFieldStyle(RoundedBorderTextFieldStyle())
                             Text("-").padding(.horizontal, -4)
                             TextField("Max", text: $viewModel.maxAmountString)
                                 .keyboardType(.decimalPad)
                                 .frame(width: 100)
                                 .textFieldStyle(RoundedBorderTextFieldStyle())
                         }
                    } // End Filters Section
                } // End Form
                 // Let the Form determine its intrinsic height
                 // Make the Form take less vertical space if possible
                .frame(maxHeight: 300) // You might need to experiment with this maxHeight for Filters only
                .padding(.bottom, 10) // Add padding below the Form

                // ADD: Loading overlay for filtering
                ZStack {
                    // --- Summary Section (Outside the Form) ---
                    VStack(alignment: .leading, spacing: 8) {
                         Text("SUMMARY")
                             .font(.caption)
                             .foregroundColor(.secondary)
                             .padding(.horizontal) // Add horizontal padding to match Form inset

                         // Use HStack + Spacer for reliable layout outside Form
                         HStack {
                             Text("Total Donations:")
                             Spacer()
                             Text(formatCurrency(viewModel.totalFilteredAmount))
                         }
                         .padding(.horizontal)

                         HStack {
                             Text("Average Donation:")
                             Spacer()
                             Text(formatCurrency(viewModel.averageFilteredAmount))
                         }
                         .padding(.horizontal)

                         HStack {
                             Text("Number of Donations:")
                             Spacer()
                             Text("\(viewModel.filteredCount)")
                         }
                         .padding(.horizontal)
                     }
                     .padding(.bottom) // Add padding below summary
                    .opacity(viewModel.isFilteringInProgress ? 0.3 : 1.0)

                    if viewModel.isFilteringInProgress {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Updating Results...")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }

                Divider()

                // MODIFY: Results section with loading state
                VStack(alignment: .leading) {
                    Text("Matching Donations (\(viewModel.filteredCount))")
                        .font(.headline)
                        .padding([.top, .leading])
                        .padding(.bottom, 5)

                    if viewModel.isLoading {
                        ProgressView("Loading Report...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.isFilteringInProgress {
                        // Show nothing here as we have the overlay above
                        EmptyView()
                    } else if let errorMsg = viewModel.errorMessage {
                        VStack { /* ... Error content ... */ }
                         .padding()
                         .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.filteredReportItems.isEmpty {
                        Text("No donations match the selected filters.")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    } else {
                        List {
                            ForEach(viewModel.filteredReportItems) { item in
                                DonationReportRow(item: item)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .opacity(viewModel.isFilteringInProgress ? 0.3 : 1.0)
                    }
                }
            } // End Main VStack
            .navigationTitle("Donation Report")
            .onTapGesture { hideKeyboard() }
            .sheet(isPresented: $showingDonorSearchView) {
                 DonorSearchSelectionView { selectedDonor in
                     viewModel.donorSelected(selectedDonor)
                 }
                 .environmentObject(donorObject)
             }
        } // End NavigationView
         .navigationViewStyle(.stack)
    }

    // Helper function to format currency (Unchanged)
     private func formatCurrency(_ amount: Double) -> String {
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
   // ... same as before ...
    let item: DonationReportItem

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
                    .foregroundColor(.green)
                Text(item.donationDate, formatter: DonationReportViewModel.dateFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

     private func formatCurrency(_ amount: Double) -> String {
         return DonationReportViewModel.currencyFormatter.string(for: amount) ?? "$0.00"
     }
}

// --- Preview ---
struct DonationReportView_Previews: PreviewProvider {
    static var previews: some View {
        // Need to provide environment objects for preview if used
        DonationReportView()
            .environmentObject(DonorObjectClass()) // Provide mock/empty object
    }
}
