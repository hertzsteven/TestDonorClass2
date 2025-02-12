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
    
    func loadCampaigns() async {
        await campaignObject.loadCampaigns()
        filterCampaigns()
    }
    
    func performSearch(with stext: String) async {
        // If empty, load all campaigns
        if stext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            await loadCampaigns()
            return
        }
        await campaignObject.searchCampaigns(stext)
        filterCampaigns()
    }
    
    func setNotLoaded() {
        campaignObject.setNotLoaded()
    }
    
    private func filterCampaigns() {
        guard selectedFilter != .all else { return }
        
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
