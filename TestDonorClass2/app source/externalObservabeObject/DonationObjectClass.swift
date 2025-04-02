    //
    //  DonationObjectClass.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz
    //

    import Foundation
    import GRDB

    class DonationObjectClass: ObservableObject {
        // MARK: - Published Properties
        @Published var donations: [Donation] = []
        @Published var errorMessage: String?
        @Published var loadingState: LoadingState = .notLoaded
        
        // MARK: - Private Properties
        private let repository: any DonationSpecificRepositoryProtocol
        

        // --- CHANGE 1: Designated Initializer ---
        // Requires the repository protocol, doesn't throw
        init(repository: any DonationSpecificRepositoryProtocol) {
            self.repository = repository
        }

        // --- CHANGE 2: Convenience Initializer ---
        // Takes no arguments, throws because creating the default repository can throw
        convenience init() throws {
            do {
                // Try to create the default repository instance
                let defaultRepository = try DonationRepository()
                // Call the designated initializer
                self.init(repository: defaultRepository)
            } catch {
                print("Failed to initialize DonationObjectClass: Could not create repository. \(error)")
                // Re-throw the error so the caller knows initialization failed
                throw error // You could wrap this in a custom error if needed
            }
        }
        
        // MARK: - Data Loading
        func loadDonations() async {
            print("Starting to load donations")
            guard loadingState == .notLoaded else {
                print("Skipping load - current state: \(loadingState)")
                return
            }
                
            await MainActor.run { loadingState = .loading }
                
            do {
                let fetchedDonations = try await repository.getAll()
                print("Fetched donations count: \(fetchedDonations.count)")
                await MainActor.run {
                    self.donations = fetchedDonations
                    self.loadingState = .loaded
                    print("Updated donations array count: \(self.donations.count)")
                }
            } catch {
                print("Error loading donations: \(error.localizedDescription)")
                await MainActor.run {
                    self.loadingState = .error(error.localizedDescription)
                    self.errorMessage = error.localizedDescription
                }
            }
        }
            
        // MARK: - CRUD Operations
        func addDonation(_ donation: Donation) async throws {
            try await repository.insert(donation)
            await MainActor.run {
                self.donations.append(donation)
            }
            // Notify any listeners that totals need to be updated
            await MainActor.run {
                NotificationCenter.default.post(
                    name: NSNotification.Name("DonationAdded"),
                    object: nil,
                    userInfo: ["donorId": donation.donorId]
                )
            }
        }
            
        func updateDonation(_ donation: Donation) async throws {
            try await repository.update(donation)
            await MainActor.run {
                if let index = donations.firstIndex(where: { $0.id == donation.id }) {
                    donations[index] = donation
                }
            }
        }
            
        func deleteDonation(_ donation: Donation) async throws {
            try await repository.delete(donation)
            await MainActor.run {
                donations.removeAll { $0.id == donation.id }
            }
        }
            
        // MARK: - Specialized Queries
        func loadDonationsForDonor(donorId: Int) async throws {
            let donorDonations = try await repository.getDonationsForDonor(donorId: donorId)
            await MainActor.run {
                self.donations = donorDonations
            }
        }
            
        func loadDonationsForCampaign(campaignId: Int) async throws {
            let campaignDonations = try await repository.getDonationsForCampaign(campaignId: campaignId)
            await MainActor.run {
                self.donations = campaignDonations
            }
        }
            
        // MARK: - Error Handling
        @MainActor
        func clearError() {
            errorMessage = nil
        }
            
        // Add total donations calculation method
        func getTotalDonationsAmount(forDonorId donorId: Int) async throws -> Double {
            let totalAmount = try await repository.getTotalDonationsAmount(forDonorId: donorId)
            return totalAmount
        }
    }
