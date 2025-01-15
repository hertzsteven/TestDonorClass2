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
        
        // MARK: - Initialization
        init(repository: CampaignRepository = CampaignRepository()) {
            self.repository = repository
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
                let fetchedCampaigns = try await repository.getAll()
                print("Fetched campaigns count: \(fetchedCampaigns.count)")
                await MainActor.run {
                    self.campaigns = fetchedCampaigns
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
                let allCampaigns = try await repository.getAll()
                let filteredCampaigns = allCampaigns.filter { campaign in
                    campaign.name.localizedCaseInsensitiveContains(query) ||
                    campaign.campaignCode.localizedCaseInsensitiveContains(query) ||
                    (campaign.description?.localizedCaseInsensitiveContains(query) ?? false)
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
            let fetchedCampaigns = try await repository.getAll()
            await MainActor.run {
                self.campaigns = fetchedCampaigns
            }
        }
        
        func updateCampaign(_ campaign: Campaign) async throws {
            try await repository.update(campaign)
            await MainActor.run {
                if let index = campaigns.firstIndex(where: { $0.id == campaign.id }) {
                    campaigns[index] = campaign
                }
            }
        }
        
        func deleteCampaign(_ campaign: Campaign) async throws {
            try await repository.delete(campaign)
            await MainActor.run {
                campaigns.removeAll { $0.id == campaign.id }
            }
        }
        
        // MARK: - Error Handling
        @MainActor
        func clearError() {
            errorMessage = nil
        }
    }
