    //
    //  DonorListView.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz on 12/24/24.
    //

    import SwiftUI

    // MARK: - Main List View
    struct DonorListView: View {
        @EnvironmentObject var donorObject: DonorObjectClass
        @StateObject private var viewModel: DonorListViewModel
        @State private var showingAddDonor = false
        
    //    init(donorObject: DonorObjectClass) {
    //        _viewModel = StateObject(wrappedValue: DonorListViewModel(donorObject: donorObject))
    //    }
        init(donorObject: DonorObjectClass) {
            _viewModel = StateObject(wrappedValue: DonorListViewModel(donorObject: donorObject))
        }

        var body: some View {
            Group {
                switch donorObject.loadingState {
                    
                case .notLoaded:
                    let _ = print("Not loaded yet")
                    LoadingView(message: "Initializing...")
                    
                case .loading:
                    let _ = print("loading")
                    LoadingView(message: "Loading donors...")
                    
                case .loaded:
                    let _ = print("loaded")
                    donorList
                    
                case .error(let message):
                    let _ = print("in error")
                    ErrorView(message: message) {
                        Task {
                            print("Retrying...")
                            await donorObject.loadDonors()
                            print("Retry complete")
                        }
                    }
                }
            }
            .navigationTitle("Donors")
            
            .searchable(text: $viewModel.searchText)
            
            .onChange(of: viewModel.searchText, initial: false) { oldValue, newValue in
                Task {
                    await viewModel.performSearch()
                }
            }

            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddDonor = true }) {
                        Label("Add Donor", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddDonor) {
//            NavigationView {
                    DonorEditView(mode: .add)
//            }
            }
        }
        
        private var donorList: some View {
            List {
                if donorObject.donors.isEmpty {
                    EmptyStateView(
                        message: "No donors found",
                        action: { Task { await donorObject.loadDonors() }},
                        actionTitle: "Refresh"
                    )
                } else {
                    ForEach(donorObject.donors) { donor in
                        NavigationLink(destination: DonorDetailView(donor: donor)) {
                            DonorRowView(donor: donor)
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            if let index = indexSet.first {
                                try? await donorObject.deleteDonor(donorObject.donors[index])
                            }
                        }
                    }
                }
            }
        }
    }





    // MARK: - Support Views
    struct LoadingView: View {
        let message: String
        
        var body: some View {
            VStack {
                ProgressView()
                    .padding()
                Text(message)
                    .foregroundColor(.secondary)
            }
        }
    }

    struct ErrorView: View {
        let message: String
        let retryAction: () -> Void
        
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                Text("Error")
                    .font(.title)
                
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("Retry It") {
                    retryAction()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    struct EmptyStateView: View {
        let message: String
        let action: (() -> Void)?
        let actionTitle: String?
        
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
                
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                if let action = action, let actionTitle = actionTitle {
                    Button(actionTitle) {
                        action()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }

    //
    //  DonorViews.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz on 12/24/24.
    //

    import SwiftUI

    #Preview {
        NavigationView {
            DonorListView(donorObject: DonorObjectClass())
                .environmentObject(DonorObjectClass())
        }
    }

    struct DonorViews_Previews: PreviewProvider {
        // Sample data
        static let sampleDonor = Donor(
    //        id: 1,
            firstName: "John",
            lastName: "Doe",
            jewishName: "Yaakov",
            address: "123 Main St",
            city: "New York",
            state: "NY",
            zip: "10001",
            email: "john@example.com",
            phone: "555-555-5555",
            notes: "Important donor"
        )
        
        // Sample donor object with different states
        static var loadedDonorObject: DonorObjectClass = {
            let object = DonorObjectClass()
            object.donors = [sampleDonor]
            object.loadingState = .loaded
            return object
        }()
        
        static var emptyDonorObject: DonorObjectClass = {
            let object = DonorObjectClass()
            object.donors = []
            object.loadingState = .loaded
            return object
        }()
        
        static var loadingDonorObject: DonorObjectClass = {
            let object = DonorObjectClass()
            object.loadingState = .loading
            return object
        }()
        
        static var errorDonorObject: DonorObjectClass = {
            let object = DonorObjectClass()
            object.loadingState = .error("Failed to load donors")
            return object
        }()
        
        static var previews: some View {
            Group {
                // Main List View - Different States
                NavigationView {
                    DonorListView(donorObject: loadedDonorObject)
                        .environmentObject(loadedDonorObject)
                }
                .previewDisplayName("List View - Loaded")
                
                NavigationView {
                    DonorListView(donorObject: emptyDonorObject)
                        .environmentObject(emptyDonorObject)
                }
                .previewDisplayName("List View - Empty")
                
                NavigationView {
                    DonorListView(donorObject: loadingDonorObject)
                        .environmentObject(loadingDonorObject)
                }
                .previewDisplayName("List View - Loading")
                
                NavigationView {
                    DonorListView(donorObject: errorDonorObject)
                        .environmentObject(errorDonorObject)
                }
                .previewDisplayName("List View - Error")
                
                // Detail View
                NavigationView {
                    DonorDetailView(donor: sampleDonor)
                        .environmentObject(loadedDonorObject)
                }
                .previewDisplayName("Detail View")
                
                // Row View
                DonorRowView(donor: sampleDonor)
                    .environmentObject(loadedDonorObject)
                    .previewLayout(.sizeThatFits)
                    .padding()
                    .previewDisplayName("Row View")
                
                // Edit Views
                NavigationView {
                    DonorEditView(mode: .add)
                        .environmentObject(loadedDonorObject)
                }
                .previewDisplayName("Add Donor View")
                
                NavigationView {
                    DonorEditView(mode: .edit(sampleDonor))
                        .environmentObject(loadedDonorObject)
                }
                .previewDisplayName("Edit Donor View")
                
                // Support Views
                LoadingView(message: "Loading donors...")
                    .previewLayout(.sizeThatFits)
                    .padding()
                    .previewDisplayName("Loading View")
                
                ErrorView(message: "Failed to load donors") {}
                    .previewLayout(.sizeThatFits)
                    .padding()
                    .previewDisplayName("Error View")
                
                EmptyStateView(
                    message: "No donors found",
                    action: {},
                    actionTitle: "Add Donor"
                )
                    .previewLayout(.sizeThatFits)
                    .padding()
                    .previewDisplayName("Empty State View")
            }
        }
    }
