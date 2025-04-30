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
    @State private var secondarySearchText = ""
    @State private var searchResults: [Donor] = []
    @State private var filteredResults: [Donor] = []
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    
    var onDonorSelected: (Donor) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
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
                            filteredResults = []
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
                
                if !searchResults.isEmpty {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "text.magnifyingglass")
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                            
                            TextField("Filter results by address", text: $secondarySearchText)
                                .padding(.vertical, 8)
                                .disableAutocorrection(true)
                                .autocapitalization(.none)
                            
                            if !secondarySearchText.isEmpty {
                                Button(action: { secondarySearchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                                .padding(.trailing, 8)
                            }
                        }
                        .padding(6)
                        .background(Color(.systemGray6).opacity(0.7))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        
                        if !secondarySearchText.isEmpty {
                            Text("Showing \(filteredResults.count) of \(searchResults.count) results")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if searchResults.isEmpty {
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
                }

                switch (isSearching, errorMessage, searchResults.isEmpty, searchText.isEmpty) {
                case (true, _, _, _):
                    ProgressView("Searching...")
                        .padding()
                    Spacer()
                    
                case (_, .some(let error), _, _):
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
                    
                case (false, nil, true, false):
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
                    
                case (false, nil, true, true):
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
                    
                case (false, nil, false, _):
                    List {
                        ForEach(secondarySearchText.isEmpty ? searchResults : filteredResults) { donor in
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
            .onChange(of: secondarySearchText) { _, newValue in
                filterResults(query: newValue)
            }
        }
    }
    
    private func filterResults(query: String) {
        if query.isEmpty {
            filteredResults = searchResults
        } else {
            filteredResults = searchResults.filter { donor in
                let addressMatch = donor.address?.localizedCaseInsensitiveContains(query) ?? false
                let cityMatch = donor.city?.localizedCaseInsensitiveContains(query) ?? false
                let stateMatch = donor.state?.localizedCaseInsensitiveContains(query) ?? false
                return addressMatch || cityMatch || stateMatch
            }
        }
    }
    
    private func performSearch() async {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        do {
            let results = try await donorObject.searchDonorsWithReturn(searchText)
            await MainActor.run {
                self.searchResults = results
                self.filteredResults = results
                self.isSearching = false
                self.secondarySearchText = ""
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error searching: \(error.localizedDescription)"
                self.searchResults = []
                self.filteredResults = []
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
