//
//  CampaignListView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz
//

import SwiftUI

// MARK: - Main List View
struct CampaignListView: View {
    @EnvironmentObject var campaignObject: CampaignObjectClass
    @StateObject private var viewModel: CampaignListViewModel
    @State private var showingAddCampaign = false
    
    init(campaignObject: CampaignObjectClass) {
        _viewModel = StateObject(wrappedValue: CampaignListViewModel(campaignObject: campaignObject))
    }
    
    var body: some View {
        Group {
            switch campaignObject.loadingState {
            case .notLoaded:
                LoadingView(message: "Initializing...")
                
            case .loading:
                LoadingView(message: "Loading campaigns...")
                
            case .loaded:
                campaignList
                
            case .error(let message):
                ErrorView(message: message) {
                    Task {
                        await campaignObject.loadCampaigns()
                    }
                }
            }
        }
        .navigationTitle("Campaigns")
        .searchable(text: $viewModel.searchText)
        .onChange(of: viewModel.searchText) { _ in
            Task {
                await viewModel.performSearch()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddCampaign = true }) {
                    Label("Add Campaign", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCampaign) {
            CampaignEditView(mode: .add)
        }
    }
    
    private var campaignList: some View {
        List {
            if campaignObject.campaigns.isEmpty {
                EmptyStateView(
                    message: "No campaigns found",
                    action: { Task { await campaignObject.loadCampaigns() }},
                    actionTitle: "Refresh"
                )
            } else {
                ForEach(campaignObject.campaigns) { campaign in
                    NavigationLink(destination: CampaignDetailView(campaign: campaign)) {
                        CampaignRowView(campaign: campaign)
                    }
                }
                .onDelete { indexSet in
                    Task {
                        if let index = indexSet.first {
                            try? await campaignObject.deleteCampaign(campaignObject.campaigns[index])
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview Provider
#Preview {
    NavigationView {
        CampaignListView(campaignObject: CampaignObjectClass())
            .environmentObject(CampaignObjectClass())
    }
}

