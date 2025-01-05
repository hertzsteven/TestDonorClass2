    //
    //  DonorRowView.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz on 1/1/25.
    //

            //
            //  DonorRowView.swift
            //  TestDonorClass2
            //
            //  Created by Steven Hertz on 1/1/25.
            //

            import SwiftUI

            // MARK: - Row View
            struct DonorRowView: View {
                let donor: Donor
                @State private var showingDonationSheet = false
                @State private var totalDonations: Double = 0.0
                var maintenanceMode: Bool
                @EnvironmentObject var donationObject: DonationObjectClass
                
                var body: some View {
                    VStack(alignment: .leading) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(donor.fullName)
                                    .font(.headline)
                                if let address = donor.address {
                                    Text(address)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if !maintenanceMode {
                                Button(action: {
                                    showingDonationSheet = true
                                }) {
                                    Image(systemName: "dollarsign.circle")
                                        .foregroundColor(.blue)
                                        .imageScale(.large)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }

                        }
                        if !maintenanceMode {
                            Group {
                                if totalDonations > -1 {
                                    Text("Total Donations: $\(String(format: "%.2f", totalDonations))")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .task {
                                await updateTotalDonations()
                            }
                            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DonationAdded"))) { notification in
                                if let donorId = notification.userInfo?["donorId"] as? Int,
                                   donorId == donor.id {
                                    Task {
                                        await updateTotalDonations()
                                    }
                                }
                            }
                        }
                    }
                    .sheet(isPresented: $showingDonationSheet) {
                        NavigationView {
                            DonationEditView(donor: donor)
                                .environmentObject(donationObject)
                        }
                    }
                }
                
                private func updateTotalDonations() async {
                    guard let donorId = donor.id else { return }
                    do {
                        totalDonations = try await donationObject.getTotalDonationsAmount(forDonorId: donorId)
                    } catch {
                        print("Error loading total donations: \(error)")
                    }
                }
            }

            #Preview {
                DonorRowView(donor: Donor(
                    firstName: "John",
                    lastName: "Doe",
                    email: "john@example.com"
                ), maintenanceMode: false)
                .environmentObject(DonationObjectClass())
                .padding()
            }

            // End of file
