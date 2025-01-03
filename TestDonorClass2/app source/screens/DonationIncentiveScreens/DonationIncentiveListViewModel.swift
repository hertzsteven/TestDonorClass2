//
// DonationIncentiveListViewModel.swift
// TestDonorClass2
//

import Foundation

@MainActor
class DonationIncentiveListViewModel: ObservableObject {
    @Published var searchText = ""
    private let incentiveObject: DonationIncentiveObjectClass
    
    init(incentiveObject: DonationIncentiveObjectClass) {
        self.incentiveObject = incentiveObject
    }
    
    func performSearch() async {
        guard !searchText.isEmpty else {
            await incentiveObject.loadIncentives()
            return
        }
        await incentiveObject.searchIncentives(searchText)
    }
}

