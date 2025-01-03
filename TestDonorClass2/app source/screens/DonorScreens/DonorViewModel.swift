//
//  DonorViewModel.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 12/24/24.
//


import Foundation
import GRDB

@MainActor
class DonorListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchText: String = ""
    @Published var selectedDonor: Donor?
    @Published var isLoading: Bool = false
    
    // MARK: - References
    private let donorObject: DonorObjectClass
    
    // MARK: - Initialization
    init(donorObject: DonorObjectClass) {
        self.donorObject = donorObject
    }
    
    // MARK: - View Operations
    func selectDonor(_ donor: Donor?) {
        selectedDonor = donor
    }
    
    // MARK: - Search Operations
    func performSearch() async {
        isLoading = true
        do {
            donorObject.loadingState = .notLoaded
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                print("Loading all donors in search...")
                try await donorObject.loadDonors()
            } else {
                print("Loading donors matching search...")
                try await donorObject.searchDonors(searchText)
            }
            donorObject.loadingState = .loaded
        } catch {
            // Handle error if needed
        }
        isLoading = false
    }
}
