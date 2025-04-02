//
//  CampaignObjectClass.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/2/25.
//

import Foundation
import GRDB

class CampaignObjectClass: ObservableObject {
    // MARK: - Published Properties

    @Published var campaigns: [Campaign] = []
    @Published var errorMessage: String?
    @Published var loadingState: LoadingState = .notLoaded
    
    // MARK: - Private Properties
    private let repository: any CampaignSpecificRepositoryProtocol
    var allLoadedCampaigns: [Campaign] = []
    
    // MARK: - Initialization
    // REMOVE the default argument here
    init(repository: any CampaignSpecificRepositoryProtocol) { // Accept protocol type
        self.repository = repository
    }

    // Convenience init for default behavior (using real repository)
    // Use try! here, assuming DB is set up by the time this is called
    convenience init() {
        let realRepository = try! CampaignRepository()
        self.init(repository: realRepository)
    }
    
    // MARK: - Data Loading
    
    func loadCampaigns() async {
        print("Starting to load campaigns")
        guard loadingState == .notLoaded else {
            print("Skipping load - current state: \(loadingState)")
            return
        }
        
        await MainActor.run { loadingState = .loading }
        
        do {
            allLoadedCampaigns = try await repository.getAll()
            print("Fetched campaigns count: \(allLoadedCampaigns.count)")
            await refreshCampaignsFromLoaded()
            await MainActor.run {
//                self.campaigns = allLoadedCampaigns
                self.loadingState = .loaded
                print("Updated campaigns array count: \(self.campaigns.count)")
            }
        } catch {
            print("Error loading campaigns: \(error.localizedDescription)")
            await MainActor.run {
                self.loadingState = .error(error.localizedDescription)
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Search Operations
    func searchCampaigns(_ query: String) async {
        await MainActor.run { loadingState = .loading }
        
        do {
            var filteredCampaigns : [Campaign] = []
            if !query.isEmpty {
                filteredCampaigns = allLoadedCampaigns.filter { campaign in
                    campaign.name.localizedCaseInsensitiveContains(query) ||
                    campaign.campaignCode.localizedCaseInsensitiveContains(query) ||
                    (campaign.description?.localizedCaseInsensitiveContains(query) ?? false)
                }
            }else {
                    filteredCampaigns = allLoadedCampaigns
                }
            
            
            await MainActor.run {
                self.campaigns = filteredCampaigns
                self.loadingState = .loaded
            }
        } catch {
            await MainActor.run {
                self.loadingState = .error(error.localizedDescription)
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - CRUD Operations
    func addCampaign(_ campaign: Campaign) async throws {
        try await repository.insert(campaign)
        allLoadedCampaigns = try await repository.getAll()
        await refreshCampaignsFromLoaded()

    }
    
    func updateCampaign(_ campaign: Campaign) async throws {
        try await repository.update(campaign)
        if let index = allLoadedCampaigns.firstIndex(where: { $0.id == campaign.id }) {
            allLoadedCampaigns[index] = campaign
        }

        await MainActor.run {
            if let index = campaigns.firstIndex(where: { $0.id == campaign.id }) {
                campaigns[index] = campaign
            }
        }
    }
    
    func deleteCampaign(_ campaign: Campaign) async throws {
        try await repository.delete(campaign)
        allLoadedCampaigns.removeAll() { $0.id == campaign.id }
        await MainActor.run {
            campaigns.removeAll { $0.id == campaign.id }
        }
    }
    // MARK: - Error Handling
    @MainActor
    func clearCampaigns() {
        campaigns.removeAll()
    }
    
    @MainActor
    func refreshCampaignsFromLoaded() {
        campaigns.removeAll()
        campaigns = allLoadedCampaigns
    }
    
    // MARK: - Error Handling
    @MainActor
    func clearError() {
        errorMessage = nil
    }
    @MainActor
    func setNotLoaded() {
        loadingState = .notLoaded
    }
}
