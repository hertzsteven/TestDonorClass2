//
//  CampaignNameService.swift
//  TestDonorClass2
//

import Foundation

/// Resolves campaign IDs to their display names, caching results so repeated
/// lookups (e.g. from list rows) don't hit the database every time.
actor CampaignNameService {
    static let shared = CampaignNameService()

    private let repositoryFactory: () -> (any CampaignSpecificRepositoryProtocol)?
    private var repository: (any CampaignSpecificRepositoryProtocol)?
    private var cache: [Int: String] = [:]

    /// The repository is created lazily through a factory so that a database
    /// that wasn't ready at first access doesn't get cached as a permanent
    /// `nil`; each lookup retries until a repository can be built.
    init(repositoryFactory: @escaping () -> (any CampaignSpecificRepositoryProtocol)? = { try? CampaignRepository() }) {
        self.repositoryFactory = repositoryFactory
    }

    private func resolvedRepository() -> (any CampaignSpecificRepositoryProtocol)? {
        if let repository { return repository }
        repository = repositoryFactory()
        return repository
    }

    /// Returns the campaign name for the given ID, or nil if it cannot be resolved.
    func name(forCampaignId id: Int) async -> String? {
        if let cached = cache[id] {
            return cached
        }
        guard let repository = resolvedRepository() else {
            print("CampaignNameService: no repository available for campaign id \(id)")
            return nil
        }
        do {
            guard let campaign = try await repository.getOne(id) else {
                print("CampaignNameService: no campaign row found for id \(id)")
                return nil
            }
            cache[id] = campaign.name
            return campaign.name
        } catch {
            print("CampaignNameService: error loading campaign id \(id): \(error)")
            return nil
        }
    }
}
