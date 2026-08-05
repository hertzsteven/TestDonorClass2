//
//  ExternalDonationImportViewModel.swift
//  TestDonorClass2
//

import Foundation

@MainActor
@Observable
final class ExternalDonationImportViewModel {

    private let parser: ExternalDonationFileParser
    private let importService: ExternalDonationImportService
    private let campaignRepository: any CampaignSpecificRepositoryProtocol

    private(set) var fileName: String?
    private(set) var items: [ExternalDonationItem] = []
    private(set) var unreadableRowCount = 0
    private(set) var applyResult: ExternalDonationApplyResult?
    private(set) var isWorking = false
    private(set) var campaigns: [Campaign] = []

    /// Start with reachable rows so those can be finished before the rest.
    var contactFilter: ExternalDonationContactFilter = .withContact

    /// Optional campaign applied to every donation written in this wave.
    var selectedCampaignId: Int?

    var errorMessage: String?

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    init(
        importService: ExternalDonationImportService,
        campaignRepository: any CampaignSpecificRepositoryProtocol,
        parser: ExternalDonationFileParser = ExternalDonationFileParser()
    ) {
        self.importService = importService
        self.campaignRepository = campaignRepository
        self.parser = parser
    }

    // MARK: - Filtered view

    var filteredItems: [ExternalDonationItem] {
        items.filter { contactFilter.matches($0.record) }
    }

    var filteredSummary: ExternalDonationSummary {
        ExternalDonationSummary(
            items: filteredItems,
            unreadableRowCount: unreadableRowCount
        )
    }

    var withContactCount: Int {
        items.filter { $0.record.hasReachableContact }.count
    }

    var withoutContactCount: Int {
        items.count - withContactCount
    }

    /// Batch-apply only the current contact group, and only when every row in
    /// that group already has a decision.
    var canApplyFiltered: Bool {
        !isWorking && filteredSummary.applyableCount > 0
    }

    func items(for outcome: ExternalDonationOutcome) -> [ExternalDonationItem] {
        filteredItems.filter { $0.outcome == outcome }
    }

    func canApplyOne(_ item: ExternalDonationItem) -> Bool {
        !isWorking && item.decision.willWrite
    }

    func loadCampaigns() async {
        do {
            campaigns = try await campaignRepository.getAll()
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Actions

    func loadPreview(from url: URL) async {
        isWorking = true
        defer { isWorking = false }

        items = []
        unreadableRowCount = 0
        applyResult = nil
        fileName = url.lastPathComponent
        contactFilter = .withContact

        do {
            let parsed = try parser.parse(fileAt: url)
            let previewed = try await importService.buildPreview(for: parsed.records)
            items = previewed
            unreadableRowCount = parsed.unreadableRowNumbers.count
        } catch {
            fileName = nil
            errorMessage = error.localizedDescription
        }
    }

    func decide(_ decision: ExternalDonationDecision, for itemID: Int) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        items[index].decision = decision
    }

    /// Decide one row and write it immediately.
    func decideAndApply(_ decision: ExternalDonationDecision, for itemID: Int) async {
        decide(decision, for: itemID)
        guard let item = items.first(where: { $0.id == itemID }),
              canApplyOne(item) else { return }
        await apply(items: [item])
    }

    /// Write every ready row in the current contact filter.
    func applyFiltered() async {
        guard canApplyFiltered else { return }
        let ready = filteredItems.filter(\.decision.willWrite)
        await apply(items: ready)
    }

    // MARK: - Private

    private func apply(items itemsToWrite: [ExternalDonationItem]) async {
        guard !itemsToWrite.isEmpty else { return }

        isWorking = true
        defer { isWorking = false }

        do {
            applyResult = try await importService.apply(
                itemsToWrite,
                campaignId: selectedCampaignId
            )

            let previous = items
            let refreshed = try await importService.buildPreview(for: previous.map(\.record))
            items = Self.preservingDecisions(from: previous, onto: refreshed)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Keep triage choices the user already made, except for rows that are now
    /// already imported (those become skip).
    private static func preservingDecisions(
        from previous: [ExternalDonationItem],
        onto refreshed: [ExternalDonationItem]
    ) -> [ExternalDonationItem] {
        let priorByKey = Dictionary(
            uniqueKeysWithValues: previous.map { ($0.record.importKey, $0.decision) }
        )

        return refreshed.map { item in
            var updated = item
            if item.outcome == .alreadyImported {
                updated.decision = .skip
            } else if let prior = priorByKey[item.record.importKey], prior.isReady {
                updated.decision = prior
            }
            return updated
        }
    }
}
