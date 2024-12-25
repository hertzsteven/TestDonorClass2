import SwiftUI

@main
struct DonorDemoApp: App {
    @StateObject var donorObject = DonorObjectClass()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                DonorListView(donorObject: donorObject)
                    .environmentObject(donorObject)
            }
        }
    }
}


// Define loading states
enum LoadingState: Equatable {
    case notLoaded
    case loading
    case loaded
    case error(String)
    
        // Custom Equatable implementation to handle the associated value
        static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
            switch (lhs, rhs) {
            case (.notLoaded, .notLoaded):
                return true
            case (.loading, .loading):
                return true
            case (.loaded, .loaded):
                return true
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
}


class DonorObjectClasx: ObservableObject {
    @Published var donors: [Donor] = []
    @Published var loadingState: LoadingState = .notLoaded
    
    init() {
        // Initialize with not loaded state
    }
    
    @MainActor
    func updateLoadingState(_ newState: LoadingState) {
        loadingState = newState
    }
    
    @MainActor
    func updateDonorsWith(_ donorArray: Array<Donor>) {
        donors = donorArray
    }
    
    func loadDonors() async throws {
        // Check if we should proceed with loading
        guard loadingState == .notLoaded else { return }
        
        await updateLoadingState(.loading)
        
        do {
            let donors = try await getAll()
            await updateDonorsWith(donors)
            await updateLoadingState(.loaded)
            print("Loaded \(donors.count) donors")
        } catch {
            await updateLoadingState(.error(error.localizedDescription))
            throw error
        }
    }
    
    func getAll() async throws -> [Donor] {
        try await Task.sleep(for: .seconds(1))
        let donors: [Donor] = [
            Donor(firstName: "Donor 1", lastName: "Last Name 1"),
            Donor(firstName: "Donor 2", lastName: "Last Name 2"),
            Donor(firstName: "Donor 3", lastName: "Last Name 3")]
        return donors
    }
    
    func loadMockDonors() {
        // Only proceed if not loaded
        guard loadingState == .notLoaded else { return }
        
        print("Loading mock donors...")
        loadingState = .loading
        donors = []
        loadingState = .loaded
        print("Mock donors loaded: \(donors.count) donors")
    }
}

// Example view to show loading states
struct DonorSelectionView: View {
    @EnvironmentObject var donorObject: DonorObjectClass
    
    var body: some View {
        Group {
            
            switch donorObject.loadingState {
                
            case .notLoaded:
                ProgressView("Not yet loaded")
                
            case .loading:
                ProgressView("Loading donors...")
                    .progressViewStyle(CircularProgressViewStyle())
                
            case .loaded:
                if donorObject.donors.isEmpty {
                    Text("No donors available")
                } else {
                    List(donorObject.donors) { donor in
                        Text("\(donor.firstName) \(donor.lastName)")
                    }
                }
                
            case .error(let message):
                VStack {
                    Text("Error loading donors")
                        .foregroundColor(.red)
                    Text(message)
                        .font(.caption)
                    Button("Retry") {
                        Task {
                            try? await donorObject.loadDonors()
                        }
                    }
                }
            }
        }
        .navigationTitle("Donors")
    }
}
