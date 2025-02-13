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
    
    init(incentiveObject: DonationIncentiveObjectClass) {
        _viewModel = StateObject(wrappedValue: DonationIncentiveListViewModel(incentiveObject: incentiveObject))
    }
    
    var body: some View {
        Group {
            VStack {
                // Add filter picker
                Picker("Filter", selection: $viewModel.selectedFilter) {
                    ForEach(DonationIncentiveFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: viewModel.selectedFilter) { _ in
                    Task {
                        await refreshIncentives()
                    }
                }
                
                // Add search field
                HStack {
                    TextField("Search incentives", text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(viewModel.isSearching)
                    
                    Button(action: {
                        Task {
                            viewModel.isSearching = true
                            viewModel.setNotLoaded()
                            await viewModel.performSearch(with: viewModel.searchText)
                            viewModel.isSearching = false
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.isSearching)
                }
                .padding()
                
                switch incentiveObject.loadingState {
                case .notLoaded:
                    LoadingView(message: "Initializing...")
                    
                case .loading:
                    LoadingView(message: "Loading incentives...")
                    
                case .loaded:
                    VStack(spacing: 0) {
                        InfoBannerView(title: "Managing Donation Incentives")
                            .padding()
                            .background(Color(.systemBackground))
                        
                        incentiveList
                            .refreshable {
                                await refreshIncentives()
                            }
                    }
                    
                case .error(let message):
                    ErrorView(message: message) {
                        Task {
                            await incentiveObject.loadIncentives()
                        }
                    }
                }
            }
        }
        .navigationTitle("Donation Incentives")
        .searchable(text: $viewModel.searchText)
        .onChange(of: viewModel.searchText) { _ in
            Task {
                await viewModel.performSearch()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddIncentive = true }) {
                    Label("Add Incentive", systemImage: "plus")
                }
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
        .onAppear {
            Task {
                viewModel.setNotLoaded()
                await viewModel.loadIncentives()
            }
        }
    }
    
    private var incentiveList: some View {
        List {
            if incentiveObject.incentives.isEmpty {
                EmptyStateView(
                    message: "No donation incentives found",
                    action: {
                        Task {
                            viewModel.setNotLoaded()
                            await viewModel.loadIncentives()
                        }
                    },
                    actionTitle: "Refresh"
                )
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
