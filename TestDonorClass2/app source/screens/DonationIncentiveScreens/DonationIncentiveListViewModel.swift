//
// DonationIncentiveListViewModel.swift
// TestDonorClass2
//

import Foundation

enum DonationIncentiveFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case inactive = "Inactive"
    case archived = "Archived"
}

@MainActor
class DonationIncentiveListViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedFilter: DonationIncentiveFilter = .all
    private let incentiveObject: DonationIncentiveObjectClass
    @Published var isSearching = false
    
    init(incentiveObject: DonationIncentiveObjectClass) {
        self.incentiveObject = incentiveObject
    }
  
    
    func loadIncentives(forceLoad: Bool = false) async {
        guard incentiveObject.allLoadedDonationIncentives.isEmpty || forceLoad else {
            refreshIncentiveFromLoaded()
            print("It seems like there are already DonationIncentives loaded. Just Refreshing")
            return
        }
        await incentiveObject.loadIncentives()
    }

    func refreshIncentiveFromLoaded() {
        incentiveObject.refreshDonationIncentivesFromLoaded()
    }
    
//    func loadIncentives() async {
//        await incentiveObject.loadIncentives()
//        filterIncentives()
//    }
    
    func performSearch(with stext: String) async {
        if stext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            await refreshIncentiveFromLoaded()
        } else {
            await incentiveObject.searchIncentives(stext)
        }
        filterIncentives()
    }
    
//    func performSearch(with searchText: String) async {
//        // If empty, load all incentives
//        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//            await loadIncentives()
//            return
//        }
//        await incentiveObject.searchIncentives(searchText)
//        filterIncentives()
//    }
    
    func performSearch() async {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            await loadIncentives()
            return
        }
        await incentiveObject.searchIncentives(searchText)
        filterIncentives()
    }
//    
    func setNotLoaded() {
        incentiveObject.setNotLoaded()
    }
    
    private func filterIncentives() {
        guard selectedFilter != .all else { return }
        
        let filteredIncentives = incentiveObject.incentives.filter { incentive in
            switch selectedFilter {
            case .active:
                return incentive.status == .active
            case .inactive:
                return incentive.status == .inactive
            case .archived:
                return incentive.status == .archived
            case .all:
                return true
            }
        }
        
        incentiveObject.incentives = filteredIncentives
    }

//    func canDeleteIncentive(_ incentive: DonationIncentive) async -> Bool {
//        do {
//                // Get all donations that reference this incentive
//            let donations = try await incentiveObject.donationRepository.getDonations(forIncentiveId: incentive.id)
//            return donations.isEmpty
//        } catch {
//            print("Error checking donations for incentive: \(error)")
//            return false // Fail safe - prevent deletion if we can't verify
//        }
//    }
}
