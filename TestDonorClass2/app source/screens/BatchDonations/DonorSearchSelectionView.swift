//
//  DonorSearchSelectionView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 3/1/25.
//


import SwiftUI

struct DonorSearchSelectionView: View {
    
    
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var donorObject: DonorObjectClass
    
    @State private var searchText = ""
    @State private var searchResults: [Donor] = []
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    
    // Callback to return the selected donor
    var onDonorSelected: (Donor) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                    
                    TextField("Search by name, company, or address", text: $searchText)
                        .padding(.vertical, 10)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .disabled(isSearching)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 8)
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Search button
                Button {
                    Task {
                        await performSearch()
                    }
                } label: {
                    HStack {
                        Text("Search")
                        if isSearching {
                            ProgressView()
                                .padding(.leading, 5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .disabled(searchText.isEmpty || isSearching)
                
                // Results or empty state
                if isSearching {
                    ProgressView("Searching...")
                        .padding()
                    Spacer()
                } else if let error = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text(error)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Spacer()
                    }
                    .padding()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack {
                        Image(systemName: "person.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                            .padding()
                        
                        Text("No donors found matching '\(searchText)'")
                            .padding()
                        
                        Spacer()
                    }
                    .padding()
                } else if searchResults.isEmpty {
                    VStack {
                        Image(systemName: "person.text.rectangle")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                            .padding()
                        
                        Text("Enter a name, company, or address to search for donors")
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    // Search results list
                    List {
                        ForEach(searchResults) { donor in
                            DonorResultRow(donor: donor)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onDonorSelected(donor)
                                    dismiss()
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Find Donor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performSearch() async {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        do {
            // Search by name, company, or address
            let results = try await donorObject.searchDonorsWithReturn(searchText)
            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error searching: \(error.localizedDescription)"
                self.searchResults = []
                self.isSearching = false
            }
        }
    }
}

struct DonorResultRow: View {
    let donor: Donor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formatName())
                .font(.headline)
            
            if let company = donor.company, !company.isEmpty {
                Text(company)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let address = donor.address, !address.isEmpty {
                Text(address)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let city = donor.city, let state = donor.state {
                Text("\(city), \(state)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
    
    private func formatName() -> String {
        var nameComponents = [String]()
        if let firstName = donor.firstName { nameComponents.append(firstName) }
        if let lastName = donor.lastName { nameComponents.append(lastName) }
        return nameComponents.joined(separator: " ")
    }
}

// Extension for your BatchDonationViewModel
extension BatchDonationViewModel {
    // Add this method to handle selected donor from search
    func setDonorFromSearch(_ donor: Donor, for rowID: UUID) async {
        guard let rowIndex = rows.firstIndex(where: { $0.id == rowID }) else { return }
        
        await MainActor.run {
            // Set the donor ID
            rows[rowIndex].donorID = donor.id
            
            // Update the display info
            let displayName = "\(donor.company ?? "") \(donor.lastName ?? "") \(donor.firstName ?? "")"
            let address = donor.address ?? ""
            
            rows[rowIndex].displayInfo = "\(displayName) | \(address)"
            rows[rowIndex].donationOverride = globalDonation
            rows[rowIndex].donationTypeOverride = globalDonationType
            rows[rowIndex].paymentStatusOverride = globalPaymentStatus
            rows[rowIndex].isValidDonor = true
            
            // Add a new row and shift focus to it
            addRow()
            focusedRowID = rows.last?.id
        }
    }
}
