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
        @Published var theDonor: Donor? = nil
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
        
        @MainActor
        func clearDonors() {
            //        searchText = ""
            donors = []
            //        hasSearched = false
        }
        
        // Update performSearch method
        @MainActor
        func performSearch(mode: DonorSearchView.SearchMode, newValue searchText: String ) async throws {
            hasSearched = true
            guard !searchText.isEmpty else {
                donorObject.loadingState = .notLoaded
                await clearDonors()
                print("Search text empty and number of donors loaded is \(donorObject.donors.count)")
                donorObject.loadingState = .loaded
                return
            }
            
            switch mode {
            case .name:
                let theDonors =  try await donorObject.searchDonorsWithReturn(searchText)
                donors = theDonors
            case .id:
                if let theID = Int(searchText) {
                    clearDonors()
                    if let oneDonor = try  await donorObject.searchDonorByIdWithReturn(theID){
                        theDonor = oneDonor
                        donors.append(oneDonor)
                    }
                }
            }
        }
    }

