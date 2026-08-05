//
//  MockExternalDonationImportRepository.swift
//  TestDonorClass2
//

import Foundation

final class MockExternalDonationImportRepository: ExternalDonationImportRepositoryProtocol, @unchecked Sendable {
    private let donorRepository: MockDonorRepository
    private let donationRepository: MockDonationRepository

    private(set) var appliedActions: [ExternalDonationImportAction] = []

    init(
        donorRepository: MockDonorRepository,
        donationRepository: MockDonationRepository
    ) {
        self.donorRepository = donorRepository
        self.donationRepository = donationRepository
    }

    func apply(_ actions: [ExternalDonationImportAction]) async throws -> ExternalDonationApplyResult {
        appliedActions = actions
        var donorsCreated = 0
        var donationsCreated = 0

        for action in actions {
            switch action {
            case .createDonorAndDonation(let donor, let donation):
                let savedDonor = try await donorRepository.insert(donor)
                donorsCreated += 1
                var linked = donation
                linked.donorId = savedDonor.id
                _ = try await donationRepository.insert(linked)
                donationsCreated += 1

            case .createDonation(let donation):
                _ = try await donationRepository.insert(donation)
                donationsCreated += 1
            }
        }

        return ExternalDonationApplyResult(
            donorsCreated: donorsCreated,
            donationsCreated: donationsCreated,
            skippedCount: 0,
            revalidationFailureCount: 0
        )
    }
}
