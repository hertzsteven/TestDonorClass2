//
// DonationIncentiveListView.swift
// TestDonorClass2
//

import SwiftUI

struct DonationIncentiveListView: View {
    @EnvironmentObject var incentiveObject: DonationIncentiveObjectClass
    @StateObject private var viewModel: DonationIncentiveListViewModel
    @State private var showingAddIncentive = false
    
    init(incentiveObject: DonationIncentiveObjectClass) {
        _viewModel = StateObject(wrappedValue: DonationIncentiveListViewModel(incentiveObject: incentiveObject))
    }
    
    var body: some View {
        Group {
            switch incentiveObject.loadingState {
            case .notLoaded:
                LoadingView(message: "Initializing...")
                
            case .loading:
                LoadingView(message: "Loading incentives...")
                
            case .loaded:
                incentiveList
                
            case .error(let message):
                ErrorView(message: message) {
                    Task {
                        await incentiveObject.loadIncentives()
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
    }
    
    private var incentiveList: some View {
        List {
            if incentiveObject.incentives.isEmpty {
                EmptyStateView(
                    message: "No donation incentives found",
                    action: { Task { await incentiveObject.loadIncentives() }},
                    actionTitle: "Refresh"
                )
            } else {
                ForEach(incentiveObject.incentives) { incentive in
                    NavigationLink(destination: DonationIncentiveDetailView(incentive: incentive)) {
                        DonationIncentiveRowView(incentive: incentive)
                    }
                }
                .onDelete { indexSet in
                    Task {
                        if let index = indexSet.first {
                            try? await incentiveObject.deleteIncentive(incentiveObject.incentives[index])
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        DonationIncentiveListView(incentiveObject: DonationIncentiveObjectClass())
            .environmentObject(DonationIncentiveObjectClass())
    }
}

