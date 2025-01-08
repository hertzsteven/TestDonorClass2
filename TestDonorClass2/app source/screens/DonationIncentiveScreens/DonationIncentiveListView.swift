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
                    VStack(spacing: 0) {
                        InfoBannerView()
                            .padding()
                            .background(Color(.systemBackground))
                        
                        incentiveList
                    }
                    
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
            .alert("Cannot Delete Incentive", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteErrorMessage)
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
                    .onDelete { indexSet in
                        Task {
                            if let index = indexSet.first {
                                let incentive = incentiveObject.incentives[index]
//                                if await viewModel.canDeleteIncentive(incentive) {
                                    try? await incentiveObject.deleteIncentive(incentive)
//                                }
                            }
                        }
                    }
                }
            }
        }
        
        private struct InfoBannerView: View {
            var body: some View {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Managing Donation Incentives")
                        .font(.headline)
                    
                    Text("• Tap + to add a new incentive")
                    Text("• Tap any incentive to view or edit details")
                    Text("• Swipe left on an incentive to delete")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
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
