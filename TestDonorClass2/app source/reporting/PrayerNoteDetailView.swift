//
//  PrayerNoteDetailView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 4/4/25.
//


import SwiftUI

struct PrayerNoteDetailView: View {
    let donation: Donation
    @State private var donor: Donor? = nil
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.fill.questionmark")
                    .font(.title)
                    .foregroundColor(.blue)
                Text("Prayer Request")
                    .font(.headline)
            }
            
            if isLoading {
                ProgressView("Loading donor information...")
            } else {
                // Donor information
                if let donor = donor {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(donor.fullName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let address = donor.address, let city = donor.city, let state = donor.state {
                            Text("\(address), \(city), \(state)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
            
            // Prayer note content
            if let prayerNote = donation.notes, !prayerNote.isEmpty {
                Text(prayerNote)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            } else {
                Text("No prayer note content available")
                    .italic()
                    .foregroundColor(.secondary)
            }
            
            // Date information
            Text("Donation date: \(donation.donationDate, formatter: DateFormatter.shortDate)")
                .font(.caption)
                .foregroundColor(.secondary)
                
            Spacer()
        }
        .padding()
        .navigationTitle("Prayer Request")
        .task {
            await loadDonorData()
        }
    }
    
    private func loadDonorData() async {
        guard let donorId = donation.donorId else {
            isLoading = false
            return
        }
        
        do {
            // You'll need to inject or access a DonorRepository or DonorObjectClass here
            let donorRepo = try DonorRepository()
            self.donor = try await donorRepo.getOne(donorId)
        } catch {
            print("Error loading donor: \(error)")
        }
        
        isLoading = false
    }
}

// For convenience, add a date formatter extension
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
