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
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
//                                    .font(.system(size: 16, weight: .semibold))
                                if let address = donor.address {
                                    Text(address)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            // if in maintenancemode show info circle else show doller
                            Text(maintenanceMode ? Image(systemName: "info.circle") : Image(systemName: "dollarsign.circle")).foregroundStyle(.secondary)
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
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(radius: 2)
                    )

                    
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
