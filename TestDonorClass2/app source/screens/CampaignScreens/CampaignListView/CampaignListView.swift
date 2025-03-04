import SwiftUI

// MARK: - Main List View
struct CampaignListView: View {
    @EnvironmentObject var campaignObject: CampaignObjectClass
    @StateObject private var viewModel: CampaignListViewModel
    @State private var showingAddCampaign = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var searchText = ""
    @State private var isSearching = false
    
    init(campaignObject: CampaignObjectClass) {
        _viewModel = StateObject(wrappedValue: CampaignListViewModel(campaignObject: campaignObject))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            CampaignFilterView(selectedFilter: $viewModel.selectedFilter) {
                await performSearch()
            }
            
            CampaignSearchBar(searchText: $searchText,
                             isSearching: $isSearching,
                             onSearch: performSearch)
            
            InfoBannerView(title: "Managing Campaigns", type: "campaign")
                .padding(.horizontal)
                .background(Color(.systemBackground))
            
            CampaignListContent(
                campaigns: campaignObject.campaigns,
                onRefresh: refreshAll,
                onDelete: handleDelete
            )
        }
        .navigationTitle("Campaigns")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingAddCampaign) {
            CampaignEditView(mode: .add)
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .task {
            await loadInitialData()
        }
    }
    
    // MARK: - Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showingAddCampaign = true }) {
                Label("Add Campaign", systemImage: "plus")
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Task { await refreshAll() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .opacity(isSearching ? 0.5 : 1.0)
            }
            .disabled(isSearching)
        }
    }
    
    // MARK: - Helper Methods
    private func loadInitialData() async {
        viewModel.setNotLoaded()
        await viewModel.loadCampaigns()
    }
    
    private func refreshAll() async {
        viewModel.selectedFilter = .all
        searchText = ""
        viewModel.setNotLoaded()
        await viewModel.loadCampaigns(forceLoad: true)
    }
    
    private func performSearch() async {
        isSearching = true
        viewModel.setNotLoaded()
        await viewModel.performSearch(with: searchText)
        isSearching = false
    }
    
    private func handleDelete(at indexSet: IndexSet) async {
        guard let index = indexSet.first else { return }
        
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

// MARK: - Preview Provider
#Preview {
    NavigationView {
        CampaignListView(campaignObject: CampaignObjectClass())
            .environmentObject(CampaignObjectClass())
    }
}
