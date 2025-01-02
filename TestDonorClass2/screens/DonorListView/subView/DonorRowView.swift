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
    @State private var totalDonations: Double = 0
    @EnvironmentObject var donorObject: DonorObjectClass
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(donor.fullName)
                .font(.headline)
            if let email = donor.email {
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Text("Total Donations: $\(totalDonations, specifier: "%.2f")")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .task {
            do {
//                totalDonations = try await donorObject.getTotalDonations(for: donor)
            } catch {
                // Handle error if needed
            }
        }
    }
}
