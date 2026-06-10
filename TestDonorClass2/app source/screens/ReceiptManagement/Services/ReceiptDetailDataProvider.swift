//
//  ReceiptDetailDataProvider.swift
//  TestDonorClass2
//
//  Fetches the full Donation, Donor, and Campaign records for a
//  given ReceiptItem. Keeps view models thin and data-fetching
//  logic testable in isolation.
//

import Foundation

/// Bundle of related records for a single receipt's donation.
struct ReceiptDetailData: Sendable {
    let donation: Donation
    let donor: Donor?
    let campaign: Campaign?
}

/// Loads the complete database picture behind a receipt row.
struct ReceiptDetailDataProvider: Sendable {
    private let donationRepository: DonationRepository

    init(donationRepository: DonationRepository) {
        self.donationRepository = donationRepository
    }

    /// Fetches the full Donation, its linked Donor, and its linked Campaign.
    /// Throws if the donation itself cannot be found.
    func loadDetails(for receiptItem: ReceiptItem) async throws -> ReceiptDetailData {
        guard let donation = try await donationRepository.getOne(receiptItem.donationId) else {
            throw DetailLoadError.donationNotFound(id: receiptItem.donationId)
        }

        var donor: Donor?
        if let donorId = donation.donorId, !donation.isAnonymous {
            donor = try? await donationRepository.getDonorForDonation(donorId: donorId)
        }

        var campaign: Campaign?
        if let campaignId = donation.campaignId {
            campaign = try? await donationRepository.getCampaignForDonation(campaignId: campaignId)
        }

        return ReceiptDetailData(donation: donation, donor: donor, campaign: campaign)
    }

    enum DetailLoadError: LocalizedError {
        case donationNotFound(id: Int)

        var errorDescription: String? {
            switch self {
            case .donationNotFound(let id):
                return "Donation with ID \(id) was not found in the database."
            }
        }
    }
}
