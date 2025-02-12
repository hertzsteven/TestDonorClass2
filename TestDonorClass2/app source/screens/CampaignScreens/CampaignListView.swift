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
    
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var isRefreshing = false  // Add this for refresh state
    
    init(campaignObject: CampaignObjectClass) {
        _viewModel = StateObject(wrappedValue: CampaignListViewModel(campaignObject: campaignObject))
    }
        
    var body: some View {
        VStack {
            Picker("Filter", selection: $viewModel.selectedFilter) {
                ForEach(CampaignFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: viewModel.selectedFilter) { _ in
                Task {
                    await refreshCampaigns()
                }
            }
            
            HStack {
                TextField("Search campaigns", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isSearching)
                
                Button(action: {
                    Task {
                        isSearching = true
                        viewModel.setNotLoaded()
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
                .refreshable {  
                    await refreshCampaigns()
                }
        }
        .navigationTitle("Campaigns")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddCampaign = true }) {
                    Label("Add Campaign", systemImage: "plus")
                }
            }
            
            // Add refresh button
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button(action: {
//                    Task {
//                        await refreshCampaigns()
//                    }
//                }) {
//                    Label("Refresh", systemImage: "arrow.clockwise")
//                        .opacity(isRefreshing ? 0.5 : 1.0)
//                }
//                .disabled(isRefreshing)
//            }
        }
        .sheet(isPresented: $showingAddCampaign) {
            CampaignEditView(mode: .add)
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            print("-- Enter campaign list view")
            Task {
                // Set not loaded state and perform fresh load
                viewModel.setNotLoaded()
                await viewModel.loadCampaigns()
            }
        }
    }
    
    private func refreshCampaigns() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        viewModel.setNotLoaded()
        if !searchText.isEmpty {
            await viewModel.performSearch(with: searchText)
        } else {
            await viewModel.loadCampaigns()
        }
        isRefreshing = false
    }

    
    private var campaignList: some View {
        List {
            if campaignObject.campaigns.isEmpty {
                EmptyStateView(
                    message: "No campaigns found",
                    action: {
                        Task {
                            viewModel.setNotLoaded()
                            await viewModel.loadCampaigns()
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

}

// MARK: - Preview Provider
#Preview {
    NavigationView {
        CampaignListView(campaignObject: CampaignObjectClass())
            .environmentObject(CampaignObjectClass())
    }
}
