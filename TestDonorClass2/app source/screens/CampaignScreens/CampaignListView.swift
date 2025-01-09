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
    
        // Alert handling properties
    @State private var showAlert = false      // Controls alert visibility
    @State private var alertMessage = ""      // Alert message content
    
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
            // Error alert configuration
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
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
                .onDelete(perform: handleDelete)
            }
        }
    }
    private func handleDelete(at indexSet: IndexSet) {
        Task {
            if let index = indexSet.first {
                do {
                    try await campaignObject.deleteCampaign(campaignObject.campaigns[index])
                } catch {
                    await MainActor.run {
                        alertMessage = error.localizedDescription
                        showAlert = true
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

