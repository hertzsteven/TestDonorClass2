//
//  NCOADeletionImportViewModel.swift
//  TestDonorClass2
//
//  Coordinates the delete-file parser and the deletion service and holds the
//  screen's state. The decisions themselves live in NCOADeletionService.
//

import Foundation

@MainActor
@Observable
final class NCOADeletionImportViewModel {

    private let parser: NCOADeletionFileParser
    private let deletionService: NCOADeletionService

    private(set) var fileName: String?
    private(set) var items: [NCOADeletionItem] = []
    private(set) var summary: NCOADeletionSummary?
    private(set) var applyResult: NCOAApplyResult?
    private(set) var isWorking = false

    var errorMessage: String?

    /// Bridges the optional message to the Bool an alert needs.
    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    init(
        deletionService: NCOADeletionService,
        parser: NCOADeletionFileParser = NCOADeletionFileParser()
    ) {
        self.deletionService = deletionService
        self.parser = parser
    }

    var canApply: Bool {
        !isWorking && (summary?.applyableCount ?? 0) > 0
    }

    func items(for outcome: NCOADeletionOutcome) -> [NCOADeletionItem] {
        items.filter { $0.outcome == outcome }
    }

    // MARK: - Actions

    /// Reads the file and classifies every row. Writes nothing.
    func loadPreview(from url: URL) async {
        isWorking = true
        defer { isWorking = false }

        items = []
        summary = nil
        applyResult = nil
        fileName = url.lastPathComponent

        do {
            let parsed = try parser.parse(fileAt: url)
            let previewed = try await deletionService.buildPreview(for: parsed.records)

            items = previewed
            summary = NCOADeletionSummary(
                items: previewed,
                unreadableRowCount: parsed.unreadableRowNumbers.count
            )
        } catch {
            fileName = nil
            errorMessage = error.localizedDescription
        }
    }

    /// Writes the verified rows, then rebuilds the preview so the screen shows
    /// the state that now exists in the database.
    func apply() async {
        guard canApply else { return }

        isWorking = true
        defer { isWorking = false }

        let unreadableRowCount = summary?.unreadableRowCount ?? 0

        do {
            applyResult = try await deletionService.apply(items)

            let refreshed = try await deletionService.buildPreview(for: items.map(\.record))
            items = refreshed
            summary = NCOADeletionSummary(items: refreshed, unreadableRowCount: unreadableRowCount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
