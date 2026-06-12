//
//  CampaignNameService.swift
//  TestDonorClass2
//

import Foundation

/// Resolves campaign IDs to their display names, caching results so repeated
/// lookups (e.g. from list rows) don't hit the database every time.
actor CampaignNameService {
    static let shared = CampaignNameService()

    private let repository: (any CampaignSpecificRepositoryProtocol)?
    private var cache: [Int: String] = [:]

    init(repository: (any CampaignSpecificRepositoryProtocol)? = try? CampaignRepository()) {
        self.repository = repository
    }

    /// Returns the campaign name for the given ID, or nil if it cannot be resolved.
    func name(forCampaignId id: Int) async -> String? {
        if let cached = cache[id] {
            return cached
        }
        guard let repository else { return nil }
        do {
            guard let campaign = try await repository.getOne(id) else { return nil }
            cache[id] = campaign.name
            return campaign.name
        } catch {
            print("Error loading campaign name for id \(id): \(error)")
            return nil
        }
    }
}
