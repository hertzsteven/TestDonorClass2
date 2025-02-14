//
//  CampaignListViewModel.swift
//  TestDonorClass2
//
//  Created by Steven Hertz
//

import Foundation

enum CampaignFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case draft = "Draft"
}

@MainActor
class CampaignListViewModel: ObservableObject {
    @Published var selectedFilter: CampaignFilter = .all
    private let campaignObject: CampaignObjectClass
    
    init(campaignObject: CampaignObjectClass) {
        self.campaignObject = campaignObject
    }
    
    func loadCampaigns(forceLoad: Bool = false) async {
        guard campaignObject.allLoadedCampaigns.isEmpty || forceLoad else {
            refreshCampaignFromLoaded()
            print("It seems like there are already campaigns loaded. Just Refreshing")
            return
        }
        await campaignObject.loadCampaigns()
//        filterCampaigns()
    }
    
    func performSearch(with stext: String) async {
        if stext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            await refreshCampaignFromLoaded()
        } else {
            await campaignObject.searchCampaigns(stext)
        }
        filterCampaigns()
    }
    
//    func performSearch(with stext: String) async {
//        // If empty, load all campaigns
//        if stext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedFilter == .all {
//            await refreshCampaignFromLoaded()
//            return
//        }
////        refreshCampaignFromLoaded()
//        await campaignObject.searchCampaigns(stext)
//        filterCampaigns()
//    }
    
    func refreshCampaignFromLoaded() {
        campaignObject.refreshCampaignsFromLoaded()
    }
    
    func setNotLoaded() {
        campaignObject.setNotLoaded()
    }
    
    func filterCampaigns() {
        guard selectedFilter != .all else {
            return
        }
        
        let filteredCampaigns = campaignObject.campaigns.filter { campaign in
            switch selectedFilter {
            case .active:
                return campaign.status == .active
            case .completed:
                return campaign.status == .completed
            case .cancelled:
                return campaign.status == .cancelled
            case .draft:
                return campaign.status == .draft
            case .all:
                return true
            }
        }
        
        campaignObject.campaigns = filteredCampaigns
    }
}
