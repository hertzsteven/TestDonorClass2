//
//  NCOAImportViewModel.swift
//  TestDonorClass2
//
//  Coordinates the parser and the import service and holds the screen's state.
//  The decisions themselves live in NCOAImportService.
//

import Foundation

@MainActor
@Observable
final class NCOAImportViewModel {

    private let parser: NCOAFileParser
    private let importService: NCOAImportService

    private(set) var fileName: String?
    private(set) var items: [NCOAImportItem] = []
    private(set) var summary: NCOAImportSummary?
    private(set) var applyResult: NCOAApplyResult?
    private(set) var isWorking = false

    var errorMessage: String?

    /// Bridges the optional message to the Bool an alert needs.
    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    init(
        importService: NCOAImportService,
        parser: NCOAFileParser = NCOAFileParser()
    ) {
        self.importService = importService
        self.parser = parser
    }

    var hasPreview: Bool {
        summary != nil
    }

    var canApply: Bool {
        !isWorking && (summary?.applyableCount ?? 0) > 0
    }

    func items(for outcome: NCOAImportOutcome) -> [NCOAImportItem] {
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
            let previewed = try await importService.buildPreview(for: parsed.records)

            items = previewed
            summary = NCOAImportSummary(
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
            applyResult = try await importService.apply(items)

            let refreshed = try await importService.buildPreview(for: items.map(\.record))
            items = refreshed
            summary = NCOAImportSummary(items: refreshed, unreadableRowCount: unreadableRowCount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
