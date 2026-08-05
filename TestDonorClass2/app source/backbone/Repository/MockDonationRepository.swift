//
//  MockDonationRepository.swift
//  TestDonorClass2
//

import Foundation

/// In-memory stand-in for DonationRepository, used by import-service tests.
final class MockDonationRepository: DonationSpecificRepositoryProtocol, @unchecked Sendable {
    private var donations: [Donation]

    init(donations: [Donation] = []) {
        self.donations = donations
    }

    var allDonations: [Donation] { donations }

    func insert(_ item: Donation) async throws -> Donation {
        var donation = item
        if donation.id == nil {
            donation.id = (donations.compactMap(\.id).max() ?? 0) + 1
        }
        donations.append(donation)
        return donation
    }

    func getAll() async throws -> [Donation] { donations }

    func getCount() async throws -> Int { donations.count }

    func getOne(_ id: Int) async throws -> Donation? {
        donations.first { $0.id == id }
    }

    func update(_ item: Donation) async throws {
        guard let index = donations.firstIndex(where: { $0.id == item.id }) else {
            throw RepositoryError.updateFailed("Donation not found")
        }
        donations[index] = item
    }

    func delete(_ item: Donation) async throws {
        donations.removeAll { $0.id == item.id }
    }

    func deleteOne(_ id: Int) async throws {
        donations.removeAll { $0.id == id }
    }

    func getTotalDonationsAmount(forDonorId donorId: Int) async throws -> Double {
        donations
            .filter { $0.donorId == donorId }
            .map(\.amount)
            .reduce(0, +)
    }

    func getDonationsForCampaign(campaignId: Int) async throws -> [Donation] {
        donations.filter { $0.campaignId == campaignId }
    }

    func getDonationsForDonor(donorId: Int) async throws -> [Donation] {
        donations.filter { $0.donorId == donorId }
    }

    func countPendingReceipts() async throws -> Int { 0 }

    func updateReceiptStatus(donationId: Int, status: ReceiptStatus) async throws {}

    func getReceiptRequests(status: ReceiptStatus) async throws -> [Donation] {
        donations.filter { $0.receiptStatus == status }
    }

    func countReceiptsByStatus(_ status: ReceiptStatus) async throws -> Int {
        donations.filter { $0.receiptStatus == status }.count
    }

    func generateReceiptNumber() async throws -> String { "MOCK-1" }

    func existingTransactionNumbers(_ keys: [String]) async throws -> Set<String> {
        let keySet = Set(keys)
        return Set(
            donations.compactMap(\.transactionNumber).filter { keySet.contains($0) }
        )
    }
}
