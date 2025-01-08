    //
    // DonationIncentiveListViewModel.swift
    // TestDonorClass2
    //

    import Foundation

    @MainActor
class DonationIncentiveListViewModel: ObservableObject {
    @Published var searchText = ""
    let incentiveObject: DonationIncentiveObjectClass
    
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
