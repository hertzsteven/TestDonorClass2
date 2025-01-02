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
                        Button(action: {
                            showingDonationSheet = true
                        }) {
                            Image(systemName: "dollarsign.circle")
                                .foregroundColor(.blue)
                                .imageScale(.large)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    if totalDonations > 0 {
                        Text("Total Donations: $\(String(format: "%.2f", totalDonations))")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .task {
                    guard let donorId = donor.id else { return }
                    do {
                        totalDonations = try await donationObject.getTotalDonationsAmount(forDonorId: donorId)
                    } catch {
                        print("Error loading total donations: \(error)")
                    }
                }
                .sheet(isPresented: $showingDonationSheet) {
                    NavigationView {
                        DonationEditView(donor: donor)
                            .environmentObject(donationObject)
                    }
                }
            }
        }

        #Preview {
            DonorRowView(donor: Donor(
                firstName: "John",
                lastName: "Doe",
                email: "john@example.com"
            ))
            .environmentObject(DonationObjectClass())
            .padding()
        }

        // End of file
        //    // MARK: - Row View
        //    struct DonorRowView: View {
        //        let donor: Donor
        //        @State private var showingDonationSheet = false
        //        @State private var totalDonations: Double = 0.0
        //        @EnvironmentObject var donorObject: DonorObjectClass
        //
        //        var body: some View {
        //            VStack(alignment: .leading) {
        //                HStack {
        //                    VStack(alignment: .leading) {
        //                        Text(donor.fullName)
        //                            .font(.headline)
        //                        if let address = donor.address {
        //                            Text(address)
        //                                .font(.subheadline)
        //                                .foregroundColor(.secondary)
        //                        }
        //                    }
        //                    Spacer()
        //                    Button(action: {
        //                        showingDonationSheet = true
        //                    }) {
        //                        Image(systemName: "dollarsign.circle")
        //                            .foregroundColor(.blue)
        //                    }
        //                }
        //                if totalDonations > 0 {
        //                    Text("Total Donations: $\(String(format: "%.2f", totalDonations))")
        //                        .font(.caption)
        //                        .foregroundColor(.blue)
        //                }
        //            }
        //            .task {
        //                if let donorId = donor.id {
        //                    do {
        //                        totalDonations = try await donorObject.getTotalDonationsAmount(forDonorId: donorId)
        //                    } catch {
        //                        print("Error loading total donations: \(error)")
        //                    }
        //                }
        //            }
        //            .sheet(isPresented: $showingDonationSheet) {
        //                NavigationView {
        //                    DonationEditView(donor: donor)
        //                        .environmentObject(donorObject)
        //                }
        //            }
        //        }
        //    }
