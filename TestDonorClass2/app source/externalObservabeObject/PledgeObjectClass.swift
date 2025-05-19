//
//  PledgeObjectClass.swift
//  TestDonorClass2
//
//  Created by Alex Carmack on 5/20/25.
//

import Foundation
import GRDB

@MainActor
class PledgeObjectClass: ObservableObject {
    // MARK: - Published Properties
    @Published var pledges: [Pledge] = []
    @Published var errorMessage: String?
    @Published var loadingState: LoadingState = .notLoaded
    
    // MARK: - Private Properties
    private let repository: any PledgeSpecificRepositoryProtocol
    
    // Designated Initializer
    init(repository: any PledgeSpecificRepositoryProtocol) {
        self.repository = repository
        print("PledgeObjectClass initialized with provided repository.")
    }

    // Convenience Initializer
    convenience init() throws {
        do {
            let defaultRepository = try PledgeRepository()
            self.init(repository: defaultRepository)
            print("PledgeObjectClass initialized with default PledgeRepository.")
        } catch {
            print("Failed to initialize PledgeObjectClass: Could not create PledgeRepository. \(error)")
            throw error
        }
    }
    
    // MARK: - Data Loading
    func loadPledges() async {
        print("PledgeObjectClass: Starting to load pledges.")
        guard loadingState == .notLoaded || loadingState.isError else {
            print("PledgeObjectClass: Skipping load - current state: \(loadingState)")
            return
        }
            
        loadingState = .loading
                
        do {
            let fetchedPledges = try await repository.getAll()
            print("PledgeObjectClass: Fetched pledges count: \(fetchedPledges.count)")
            self.pledges = fetchedPledges
            self.loadingState = .loaded
            self.errorMessage = nil
            print("PledgeObjectClass: Updated pledges array count: \(self.pledges.count)")
        } catch {
            print("PledgeObjectClass: Error loading pledges: \(error.localizedDescription)")
            self.loadingState = .error(error.localizedDescription)
            self.errorMessage = error.localizedDescription
        }
    }
            
    // MARK: - CRUD Operations
    func addPledge(_ pledge: Pledge) async {
        loadingState = .loading
        do {
            var pledgeToAdd = pledge
            // Ensure created/updated timestamps are fresh
            let now = Date()
            pledgeToAdd.createdAt = now
            pledgeToAdd.updatedAt = now
            
            try pledgeToAdd.validate() // Validate before attempting to insert
            try await repository.insert(pledgeToAdd) // This will insert and get the ID back if auto-incremented
            
            // Re-fetch the pledge if ID was auto-assigned and needed, or simply add if ID was pre-set or not strictly needed for UI immediate update
            // For simplicity, we'll just add the passed pledge, assuming it's sufficient or will be refreshed
            // If the ID is critical and auto-generated, a fetch after insert might be better.
            // However, GRDB's insert often populates the ID back into the mutable copy.
            // Let's assume insert handles ID propagation if it's an autoincrementing PK.
            // If not, we might need to refetch or adjust how `insert` works.
            
            // For now, let's reload all pledges to ensure data consistency.
            // A more optimized approach would be to get the inserted pledge (with ID) and append.
            await loadPledges() // Simplest way to refresh UI with new data including ID
            // self.pledges.append(pledgeToAdd) // This might not have the ID if auto-generated.
            
            // loadingState = .loaded // Set by loadPledges()
            // errorMessage = nil // Set by loadPledges()
        } catch {
            print("PledgeObjectClass: Error adding pledge: \(error.localizedDescription)")
            loadingState = .error(error.localizedDescription)
            errorMessage = "Failed to add pledge: \(error.localizedDescription)"
        }
    }
            
    func updatePledge(_ pledge: Pledge) async {
        loadingState = .loading
        do {
            var pledgeToUpdate = pledge
            pledgeToUpdate.updatedAt = Date() // Ensure updatedAt is fresh
            
            try pledgeToUpdate.validate() // Validate before attempting to update
            try await repository.update(pledgeToUpdate)
            if let index = pledges.firstIndex(where: { $0.id == pledgeToUpdate.id }) {
                pledges[index] = pledgeToUpdate
            } else {
                // If not found, perhaps it's a new item or list is out of sync, reload.
                await loadPledges()
            }
            loadingState = .loaded
            errorMessage = nil
        } catch {
            print("PledgeObjectClass: Error updating pledge: \(error.localizedDescription)")
            loadingState = .error(error.localizedDescription)
            errorMessage = "Failed to update pledge: \(error.localizedDescription)"
        }
    }
            
    func deletePledge(_ pledge: Pledge) async {
        guard let pledgeId = pledge.id else {
            errorMessage = "PledgeObjectClass: Cannot delete pledge without an ID."
            loadingState = .error(errorMessage!)
            return
        }
        loadingState = .loading
        do {
            try await repository.delete(pledge)
            pledges.removeAll { $0.id == pledgeId }
            loadingState = .loaded
            errorMessage = nil
        } catch {
            print("PledgeObjectClass: Error deleting pledge: \(error.localizedDescription)")
            loadingState = .error(error.localizedDescription)
            errorMessage = "Failed to delete pledge: \(error.localizedDescription)"
        }
    }
    
    func deletePledge(at offsets: IndexSet) async {
        let pledgesToDelete = offsets.map { pledges[$0] }
        loadingState = .loading
        var firstError: Error? = nil
        
        for pledge in pledgesToDelete {
            do {
                try await repository.delete(pledge)
            } catch {
                if firstError == nil { firstError = error }
                print("PledgeObjectClass: Error deleting pledge \(pledge.id ?? -1): \(error.localizedDescription)")
            }
        }
        
        if let error = firstError {
            loadingState = .error(error.localizedDescription)
            errorMessage = "Failed to delete one or more pledges: \(error.localizedDescription)"
        } else {
            await loadPledges() // Refresh the list from repository
            // loadingState = .loaded // Set by loadPledges
            // errorMessage = nil // Set by loadPledges
        }
    }
            
    // MARK: - Specialized Queries
    func loadPledgesForDonor(donorId: Int) async {
        print("PledgeObjectClass: Loading pledges for donor ID \(donorId)")
        loadingState = .loading
        do {
            let donorPledges = try await repository.getPledgesForDonor(donorId: donorId)
            self.pledges = donorPledges
            loadingState = .loaded
            errorMessage = nil
            print("PledgeObjectClass: Loaded \(donorPledges.count) pledges for donor ID \(donorId)")
        } catch {
            print("PledgeObjectClass: Error loading pledges for donor: \(error.localizedDescription)")
            loadingState = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }
            
    func loadPledgesForCampaign(campaignId: Int) async {
        print("PledgeObjectClass: Loading pledges for campaign ID \(campaignId)")
        loadingState = .loading
        do {
            let campaignPledges = try await repository.getPledgesForCampaign(campaignId: campaignId)
            self.pledges = campaignPledges
            loadingState = .loaded
            errorMessage = nil
            print("PledgeObjectClass: Loaded \(campaignPledges.count) pledges for campaign ID \(campaignId)")
        } catch {
            print("PledgeObjectClass: Error loading pledges for campaign: \(error.localizedDescription)")
            loadingState = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }
    
    func loadPledgesByStatus(status: PledgeStatus) async {
        print("PledgeObjectClass: Loading pledges with status \(status.displayName)")
        loadingState = .loading
        do {
            let statusPledges = try await repository.getPledgesByStatus(status: status)
            self.pledges = statusPledges
            loadingState = .loaded
            errorMessage = nil
            print("PledgeObjectClass: Loaded \(statusPledges.count) pledges with status \(status.displayName)")
        } catch {
            print("PledgeObjectClass: Error loading pledges by status: \(error.localizedDescription)")
            loadingState = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }
    
    func applyDonationToPledge(pledgeId: Int, donationAmount: Double) async {
        guard donationAmount > 0 else {
            print("PledgeObjectClass: Donation amount must be positive.")
            // Optionally set an error message
            return
        }

        loadingState = .loading
        errorMessage = nil

        do {
            var pledgeToUpdate: Pledge? = pledges.first { $0.id == pledgeId }

            if pledgeToUpdate == nil {
                pledgeToUpdate = try await repository.getOne(pledgeId)
            }

            guard var pledgeToUpdate else {
                print("PledgeObjectClass: Pledge with ID \(pledgeId) not found.")
                errorMessage = "Pledge not found."
                loadingState = .error(errorMessage!)
                return
            }

            let newBalance = pledgeToUpdate.currentBalance - donationAmount
            var newStatus = pledgeToUpdate.status

            if newBalance <= 0 {
                // Pledge is fully paid or overpaid
                newStatus = .fulfilled
                // It's important the repository sets the balance to 0 if it's negative,
                // or we cap it here. The repository example caps at 0 implicitly if newBalance < 0 for .fulfilled.
                // Let's ensure the newBalance passed to repo is not negative for clarity, or that repo handles it.
                // The current repo implementation will just set the balance as calculated.
                // For this business logic layer, we might say the balance cannot be negative.
            } else if newBalance < pledgeToUpdate.pledgeAmount {
                // Pledge is partially paid
                newStatus = .partiallyFulfilled
            }
            // If newBalance == pledgeToUpdate.pledgeAmount, status remains .pledged (no change from initial)
            // Or if it was .cancelled, it should remain .cancelled. This logic might need refinement
            // based on exact business rules for status transitions (e.g., can't apply donation to .cancelled pledge).

            // For simplicity, we'll let the repository handle the exact balance value (even if negative, though
            // our UI/reports should show 0). The status update is key.
            // The repository method also has some logic for auto-setting status if not provided.
            try await repository.updatePledgeBalance(pledgeId: pledgeId, newBalance: max(0, newBalance), newStatus: newStatus)

            // Refresh the specific pledge in the local array or reload all
            if let index = pledges.firstIndex(where: { $0.id == pledgeId }) {
                // Fetch the updated pledge to ensure all fields are current
                if let updatedPledgeFromServer = try await repository.getOne(pledgeId) {
                    pledges[index] = updatedPledgeFromServer
                } else {
                    // Pledge might have been deleted or an issue occurred, reload all
                    await loadPledges()
                }
            } else {
                // Pledge was not in the local list, reload all
                await loadPledges()
            }
            
            loadingState = .loaded
        } catch {
            print("PledgeObjectClass: Error applying donation to pledge: \(error.localizedDescription)")
            loadingState = .error(error.localizedDescription)
            errorMessage = "Failed to apply donation to pledge: \(error.localizedDescription)"
        }
    }
            
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
        if loadingState.isError {
            loadingState = .notLoaded // Reset to allow reloading
        }
    }
}
