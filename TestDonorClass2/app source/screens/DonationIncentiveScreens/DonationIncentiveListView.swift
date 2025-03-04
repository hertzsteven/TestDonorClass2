//
// DonationIncentiveListView.swift
// TestDonorClass2
//

import SwiftUI

struct DonationIncentiveListView: View {
    @EnvironmentObject private var incentiveObject: DonationIncentiveObjectClass
    @StateObject private var viewModel: DonationIncentiveListViewModel
    @State private var showingAddIncentive = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var isRefreshing = false
    
    @State private var returnedFromDetail = false
    
    @State private var searchText = ""
    @State private var isSearching = false
    
    @State private var totalCount: Int = 0
    
    init(incentiveObject: DonationIncentiveObjectClass) {
        _viewModel = StateObject(wrappedValue: DonationIncentiveListViewModel(incentiveObject: incentiveObject))
    }
    
    var body: some View {
        VStack(spacing: 16) {
//            IncentiveFilterView(selectedFilter: $viewModel.selectedFilter) {
//                await performSearch()
//            }
            
//            IncentiveSearchBar(searchText: $searchText,
//                               isSearching: $isSearching,
//                               onSearch: performSearch)
//
//            InfoBannerView(title: "Managing Incentives", type: "Incentives")
//                .padding(.horizontal)
//                .background(Color(.systemBackground))
            
            // This is where you would change your content based on the state
            switch (incentiveObject.loadingState, totalCount == 0) {
            case (.loading, _):
                ProgressView("Loading incentives...")
            case (_, true):
                EmptyIncentiveStateView(onAddNew: {
                    // Now you can directly access your local state variable
                    self.showingAddIncentive = true
                })
                .frame(maxHeight: .infinity)
            case (_, false):
                // Your existing code for displaying the list
                IncentiveFilterView(selectedFilter: $viewModel.selectedFilter) {
                    await performSearch()
                }

                IncentiveSearchBar(searchText: $searchText,
                                   isSearching: $isSearching,
                                   onSearch: performSearch)
                
                InfoBannerView(title: "Managing Incentives", type: "Incentives")
                    .padding(.horizontal)
                    .background(Color(.systemBackground))
                
                IncentiveListContent(
                    incentives: incentiveObject.incentives,
                    onRefresh: refreshAll,
                    onDelete: handleDelete,
                    returnedFromDetail: $returnedFromDetail,
                    showingAddIncentive: $showingAddIncentive
                )
            }

        }
        .navigationTitle("Donation Incentives")
        .task {
            // Load the total count whenever the view appears
            do {
                totalCount = try await incentiveObject.getTotalIncentiveCount()
            } catch {
                print("Error getting total count: \(error)")
                totalCount = 0
            }
        }
            
            
            
//            IncentiveListContent(
//                incentives: incentiveObject.incentives,
//                onRefresh: refreshAll,
//                onDelete: handleDelete,
//                returnedFromDetail: $returnedFromDetail
//            )

//        }
//        .navigationTitle("Donation Incentives")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddIncentive = true }) {
                    Label("Add Incentive", systemImage: "plus")
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
    
        .sheet(isPresented: $showingAddIncentive) {
            DonationIncentiveEditView(mode: .add)
        }
        .alert("Cannot Delete Incentive", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteErrorMessage)
        }
        .task {
            await loadInitialData()
        }
    }
    
    private var incentiveListold: some View {
        List {
            if incentiveObject.incentives.isEmpty {
                EmptyIncentiveStateView(onAddNew: {
                    showingAddIncentive = true
                })
                .frame(maxHeight: .infinity)
//                EmptyStateView(
//                    message: "No donation incentives found",
//                    action: {
//                        Task {
//                            viewModel.setNotLoaded()
//                            await viewModel.loadIncentives()
//                        }
//                    },
//                    actionTitle: "Refresh"
//                )
            } else {
                ForEach(incentiveObject.incentives) { incentive in
                    NavigationLink(destination: DonationIncentiveDetailView(incentive: incentive))
                    {
                        DonationIncentiveRowView(incentive: incentive)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task {
                                do {
                                    let inUse = try await incentiveObject.isInUse(id: incentive.id!)
                                    if !inUse {
                                        try await incentiveObject.deleteIncentive(incentive)
                                    } else {
                                        deleteErrorMessage = "This incentive is currently being used in one or more donations and cannot be deleted."
                                        showDeleteError = true
                                    }
                                } catch {
                                    deleteErrorMessage = "An error occurred while checking or deleting the incentive."
                                    showDeleteError = true
                                }

                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: handleDelete)
            }
        }
    }
    
    private func loadInitialData() async {
//        defer {
//            returnedFromDetail = false
//        }
// Load the total count whenever the view appears
        do {
            totalCount = try await incentiveObject.getTotalIncentiveCount()
        } catch {
            print("Error getting total count: \(error)")
            totalCount = 0
        }
        print("-- Loading initial data returnedFromDetail: \(returnedFromDetail)")
        if !returnedFromDetail {
            print("-- before viewmodelsetnotloaded")
            viewModel.setNotLoaded()
            await viewModel.loadIncentives()
        } else {
            print("-- Not loading initial data because returnedFromDetail is true")
        }
    }
    
    private func refreshAll() async {
        viewModel.selectedFilter = .all
        searchText = ""
        viewModel.setNotLoaded()
        await viewModel.loadIncentives(forceLoad: true)
    }
 
    
    private func performSearch() async {
        isSearching = true
        viewModel.setNotLoaded()
        await viewModel.performSearch(with: searchText)
        isSearching = false
        do {
            totalCount = try await incentiveObject.getTotalIncentiveCount()
            print("Total count after search: \(totalCount)")
        } catch {
            print("Error getting total count: \(error)")
            totalCount = 0
        }
    }

    private func handleDelete(at indexSet: IndexSet) {
        Task {
            if let index = indexSet.first {
                let incentive = incentiveObject.incentives[index]
                do {
                    try await incentiveObject.deleteIncentive(incentive)
                } catch {
                    await MainActor.run {
                        deleteErrorMessage = error.localizedDescription
                        showDeleteError = true
                    }
                }
            }
        }
    }
    

    
    private func refreshIncentives() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        viewModel.setNotLoaded()
        if !viewModel.searchText.isEmpty {
            await viewModel.performSearch(with: viewModel.searchText)
        } else {
            await viewModel.loadIncentives()
        }
        isRefreshing = false
    }
}

// MARK: - Preview
struct DonationIncentiveListView_Previews: PreviewProvider {
    static var previews: some View {
        let mockIncentiveObject: DonationIncentiveObjectClass = {
            let object = DonationIncentiveObjectClass()
            object.incentives = [
                DonationIncentive(name: "Light a Candle", dollarAmount: 36.00),
                DonationIncentive(name: "Tefilla by kever", dollarAmount: 55.00)
            ]
            object.loadingState = .loaded
            return object
        }()
        
        NavigationView {
            DonationIncentiveListView(incentiveObject: mockIncentiveObject)
                .environmentObject(mockIncentiveObject)
        }
    }
}
