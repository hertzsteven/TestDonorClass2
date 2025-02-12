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
    
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    // Alert handling properties
    @State private var showAlert = false      // Controls alert visibility
    @State private var alertMessage = ""      // Alert message content
    
    @State private var searchText = ""
    @State private var isSearching = false
    
    init(campaignObject: CampaignObjectClass) {
        _viewModel = StateObject(wrappedValue: CampaignListViewModel(campaignObject: campaignObject))
    }
    
    var body: some View {
        
        VStack {
            
            HStack {
                TextField("Search campaigns", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isSearching)
                
                Button(action: {
                    Task {
                        isSearching = true
                        await viewModel.performSearch(with: searchText)
                        isSearching = false
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.blue)
                }
                .disabled(isSearching)
            }
            .padding()
            
            campaignList
        }
        
        //        Group {
        //            switch campaignObject.loadingState {
        //            case .notLoaded:
        //                LoadingView(message: "Initializing...")
        //
        //            case .loading:
        //                LoadingView(message: "Loading campaigns...")
        //
        //            case .loaded:
        //                    campaignList
        //
        //
        //            case .error(let message):
        //                ErrorView(message: message) {
        //                    Task {
        //                        await campaignObject.loadCampaigns()
        //                    }
        //                }
        //            }
        //        }
        .navigationTitle("Campaigns")
        //        .searchable(text: $viewModel.searchText)
        //        .onChange(of: viewModel.searchText) { _ in
        //            Task {
        //                await viewModel.performSearch()
        //            }
        //        }
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
        .onAppear {
            print("Enter campaign list view")
            Task {
                // Only load if not already loaded
                if case .notLoaded = campaignObject.loadingState {
                    await campaignObject.loadCampaigns()
                }
            }
        }
    }
    
    private var campaignList: some View {
        List {
            if campaignObject.campaigns.isEmpty {
                EmptyStateView(
                    message: "No campaigns found",
                    action: {
                        Task {
                            await campaignObject.loadCampaigns()
                        }
                    },
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
    
    private func toggleSidebar() {
        withAnimation {
            columnVisibility = (columnVisibility == .all) ? .detailOnly : .all
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
