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
    let isSelected: Bool
    @State private var showingDonationSheet = false
    @State private var totalDonations: Double = 0.0
    var maintenanceMode: Bool
    @EnvironmentObject var donationObject: DonationObjectClass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Name and Info/Dollar Icon
            HStack {
                Text(donor.fullName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: maintenanceMode ? "info.circle" : "dollarsign.circle")
                    .foregroundStyle(.secondary)
                    .imageScale(.small)
                    .opacity(0.6)
            }
            
            // Address
            if let address = donor.address {
                Text(address)
                    .font(.system(size: 12))
                    .foregroundColor(Color(.systemGray))
            }
            
            // Total Donations
            if !maintenanceMode {
                Text("Total Donations: ")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.systemGray)) +
                Text("$\(String(format: "%.2f", totalDonations))")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.08) : Color(.systemBackground))
        )
        .contentTransition(.interpolate)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .task {
            if !maintenanceMode {
                await updateTotalDonations()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DonationAdded"))) { notification in
            if let donorId = notification.userInfo?["donorId"] as? Int,
               donorId == donor.id {
                Task {
                    await updateTotalDonations()
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
