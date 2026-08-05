//
//  HoldingDonorService.swift
//  TestDonorClass2
//
//  Get-or-create the shared organization donors used by external imports
//  (Anonymous / Unidentified, The Donors Fund).
//

import Foundation

enum HoldingDonorKind: String, Sendable {
    case anonymous = "Anonymous / Unidentified"
    case donorsFund = "The Donors Fund"

    var companyName: String { rawValue }

    var donorSource: DonorSource {
        switch self {
        case .anonymous: .other
        case .donorsFund: .certificateOrganization
        }
    }
}

struct HoldingDonorService {
    private let repository: any DonorSpecificRepositoryProtocol

    init(repository: any DonorSpecificRepositoryProtocol) {
        self.repository = repository
    }

    init() throws {
        self.init(repository: try DonorRepository())
    }

    /// Returns the existing holding donor, or creates it when missing.
    func donor(for kind: HoldingDonorKind) async throws -> Donor {
        let donors = try await repository.getAll()
        if let existing = donors.first(where: { Self.matches($0, kind: kind) }) {
            return existing
        }

        let created = Donor(
            company: kind.companyName,
            donorSource: kind.donorSource.rawValue,
            notes: "Created automatically for external donation import."
        )
        return try await repository.insert(created)
    }

    /// In-memory lookup used during preview when the full donor list is already loaded.
    static func find(in donors: [Donor], kind: HoldingDonorKind) -> Donor? {
        donors.first { matches($0, kind: kind) }
    }

    private static func matches(_ donor: Donor, kind: HoldingDonorKind) -> Bool {
        PostalAddressNormalizer.normalized(donor.company)
            == PostalAddressNormalizer.normalized(kind.companyName)
    }
}
