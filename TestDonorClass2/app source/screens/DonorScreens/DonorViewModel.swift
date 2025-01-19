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
    @Published var maintenanceMode: Bool
    
    // MARK: - References
    private let donorObject: DonorObjectClass
    
    // MARK: - Initialization
    init(donorObject: DonorObjectClass, maintenanceMode: Bool) {
        self.donorObject = donorObject
        self.maintenanceMode = maintenanceMode
    }
    
    // MARK: - View Operations
    func selectDonor(_ donor: Donor?) {
        selectedDonor = donor
    }
    
    // MARK: - Search Operations
    func performSearch() async {
        isLoading = true
        do {
            await MainActor.run { donorObject.loadingState = .notLoaded }
//            donorObject.loadingState = .notLoaded
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                print("Loading all donors in search...")
//                try await donorObject.loadDonors()
            } else {
                print("Loading donors matching search...")
                try await donorObject.searchDonors(searchText)
            }
            await MainActor.run { donorObject.loadingState = .loaded }
//            donorObject.loadingState = .loaded
        } catch {
            // Handle error if needed
        }
        isLoading = false
    }
    
        // Update performSearch method
    @MainActor
    func performSearch(mode: DonorListView.SearchMode, newValue searchText: String ) async throws {
        print("Performing search... new \(searchText)")
        
            guard !searchText.isEmpty else {
//                await MainActor.run {
                    donorObject.loadingState = .notLoaded
                await donorObject.clearDonors()
//                }
//                donorObject.loadingState = .notLoaded
//                await MainActor.run { donorObject.clearDonors() }
                print("Search text empty and number of donors loaded is \(donorObject.donors.count)")
//                await MainActor.run { donorObject.loadingState = .loaded }
                donorObject.loadingState = .loaded
                return
            }
            
            switch mode {
            case .name:
                try await donorObject.searchDonors(searchText)
            case .id:
                if let id = Int(searchText) {
                  try  await donorObject.searchDonorById(id)
                }
            }
        }

}
