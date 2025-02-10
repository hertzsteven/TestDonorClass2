//
//  DonorSearchViewModel.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/9/25.
//


import SwiftUI

// MARK: - ViewModel
class DonorSearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var donors: [Donor] = []
    @Published var hasSearched = false
    
        // MARK: - References
        private let donorObject: DonorObjectClass
     
   
    private let allDonors: [Donor]
   
    init(donorObject: DonorObjectClass) {
        self.donorObject = donorObject
        self.allDonors = MockDonorGenerator.generateMockDonors()
    }
    
    func searchForDonors() {
        hasSearched = true
        
        if searchText.isEmpty {
            donors = allDonors
        } else {
            let searchText = searchText.lowercased()
            donors = allDonors.filter { donor in
                let lastNameMatch = donor.lastName?.lowercased().contains(searchText) ?? false
                let firstNameMatch = donor.firstName?.lowercased().contains(searchText) ?? false
                let companyMatch = donor.company?.lowercased().contains(searchText) ?? false
                
                return lastNameMatch || firstNameMatch || companyMatch
            }
        }
    }
    
    func clearSearch() {
        searchText = ""
        donors = []
        hasSearched = false
    }
}

// MARK: - Views
struct DonorSearchView: View {
//    @StateObject private var viewModel = DonorSearchViewModel(donorObject: DonorObjectClass())
    
    @StateObject private var viewModel: DonorSearchViewModel
    
    init(donorObject: DonorObjectClass) {
        _viewModel = StateObject(wrappedValue: DonorSearchViewModel(donorObject: donorObject))
    }

    
    var body: some View {
//        NavigationView {
            VStack {
                searchBar
                if viewModel.hasSearched {
                      if viewModel.donors.isEmpty {
                          noResultsView
                      } else {
                          donorList2
                      }
                } else {
                    initialStateView
                }
            }
//            .navigationTitle("Donors")
//        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search donors...", text: $viewModel.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .submitLabel(.search)
            if !viewModel.searchText.isEmpty {
                  Button(action: {
                      viewModel.clearSearch()
                  }) {
                      Image(systemName: "xmark.circle.fill")
                          .foregroundColor(.gray)
                  }
              }
            
                Button(action: {
                viewModel.searchForDonors()
            }) {
                Text("Search")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        }

    private var initialStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("Enter search terms and press Search")
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("No donors found")
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
    }
    private var donorList2: some View {
        List(viewModel.donors, id: \.uuid) { donor in
            NavigationLink(destination: DonationEditView(donor: donor)) {
                DonorRowView2(donor: donor)
            }
        }
    }
}

struct DonorRowView2: View {
    let donor: Donor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(formatName(donor))
                    .font(.headline)
                Spacer()
                if let company = donor.company {
                    Text(company)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            if let email = donor.email {
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            HStack {
                if let phone = donor.phone {
                    Text(phone)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                if let city = donor.city, let state = donor.state {
                    Text("\(city), \(state)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatName(_ donor: Donor) -> String {
        var components: [String] = []
        if let salutation = donor.salutation { components.append(salutation) }
        if let firstName = donor.firstName { components.append(firstName) }
        if let lastName = donor.lastName { components.append(lastName) }
        return components.joined(separator: " ")
    }
}

struct DonorDetailView2: View {
    let donor: Donor
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Contact Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Contact Information")
                        .font(.headline)
                    
                    if let email = donor.email {
                        HStack {
                            Image(systemName: "envelope")
                            Text(email)
                        }
                    }
                    
                    if let phone = donor.phone {
                        HStack {
                            Image(systemName: "phone")
                            Text(phone)
                        }
                    }
                }
                
                // Address
                if let address = donor.address {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Address")
                            .font(.headline)
                        
                        Text(address)
                        if let city = donor.city, let state = donor.state, let zip = donor.zip {
                            Text("\(city), \(state) \(zip)")
                        }
                    }
                }
                
                // Notes
                if let notes = donor.notes {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        Text(notes)
                    }
                }
                
                // Dates
                VStack(alignment: .leading, spacing: 8) {
                    Text("Record Information")
                        .font(.headline)
                    Text("Created: \(formatDate(donor.createdAt))")
                    Text("Updated: \(formatDate(donor.updatedAt))")
                }
            }
            .padding()
        }
        .navigationTitle(formatName(donor))
    }
    
    private func formatName(_ donor: Donor) -> String {
        var components: [String] = []
        if let salutation = donor.salutation { components.append(salutation) }
        if let firstName = donor.firstName { components.append(firstName) }
        if let lastName = donor.lastName { components.append(lastName) }
        return components.joined(separator: " ")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


struct DonorSearchView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy DonorObjectClass instance.
        // Adjust the initializer if DonorObjectClass requires parameters.
        let dummyDonorObject = DonorObjectClass()
        
        // Wrap in a NavigationView if you want to preview NavigationLinks.
        NavigationView {
            DonorSearchView(donorObject: dummyDonorObject)
        }
        // Optionally, set a preview device or color scheme:
        .previewDevice("iPhone 13")
        .preferredColorScheme(.light) // Change to .dark to preview dark mode.
    }
}

//// Preview provider
//struct DonorSearchView_Previews: PreviewProvider {
//    static var previews: some View {
//        DonorSearchView()
//    }
//}
