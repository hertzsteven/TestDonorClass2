//
//  CampaignListViewModel.swift
//  TestDonorClass2
//
//  Created by Steven Hertz
//

import Foundation

@MainActor
class CampaignListViewModel: ObservableObject {
    @Published var searchText = ""
    private let campaignObject: CampaignObjectClass
    
    init(campaignObject: CampaignObjectClass) {
        self.campaignObject = campaignObject
    }
    
    func performSearch() async {
        guard !searchText.isEmpty else {
            await campaignObject.loadCampaigns()
            return
        }
        await campaignObject.searchCampaigns(searchText)
    }
    
    func performSearch(with stext: String) async {
        guard !stext.isEmpty else {
            await campaignObject.loadCampaigns()
            return
        }
        await campaignObject.searchCampaigns(stext)
    }
    
    func clearSearch() {
        searchText = ""
        campaignObject.clearCampaigns()
    }
}
