import Foundation

/// Persists imported receipt PDF templates to the app's Documents
/// directory, namespaced per active organization, and provides metadata
/// (original filename + import date + size) for the Settings UI.
///
/// Single responsibility: file I/O. It does not validate field names —
/// that is `ReceiptTemplateValidator`'s job.
struct ReceiptTemplateStore {
    enum StoreError: Error, LocalizedError {
        case noActiveOrganization
        case readFailed(URL)
        case writeFailed(underlying: Error)
        case deleteFailed(underlying: Error)

        var errorDescription: String? {
            switch self {
            case .noActiveOrganization:
                return "No organization is currently selected; cannot import a template."
            case .readFailed(let url):
                return "Could not read the file at \(url.lastPathComponent)."
            case .writeFailed(let underlying):
                return "Could not save the imported template: \(underlying.localizedDescription)"
            case .deleteFailed(let underlying):
                return "Could not delete the existing template: \(underlying.localizedDescription)"
            }
        }
    }

    struct ImportedMetadata: Equatable {
        let url: URL
        let originalFilename: String
        let importedAt: Date
        let fileSize: Int
    }

    private let prefixProvider: () -> String?
    private let fileManager: FileManager
    private let userDefaults: UserDefaults

    init(prefixProvider: @escaping () -> String? = ReceiptTemplatePaths.currentOrgPrefix,
         fileManager: FileManager = .default,
         userDefaults: UserDefaults = .standard) {
        self.prefixProvider = prefixProvider
        self.fileManager = fileManager
        self.userDefaults = userDefaults
    }

    /// Copies the user-picked PDF into the per-org slot, replacing any
    /// previous import. Records original filename + import date for UI.
    @discardableResult
    func importTemplate(from sourceURL: URL) throws -> ImportedMetadata {
        guard let prefix = prefixProvider(), !prefix.isEmpty else {
            throw StoreError.noActiveOrganization
        }

        let needsScope = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if needsScope { sourceURL.stopAccessingSecurityScopedResource() }
        }

        let data: Data
        do {
            data = try Data(contentsOf: sourceURL)
        } catch {
            throw StoreError.readFailed(sourceURL)
        }

        let destDir = ReceiptTemplatePaths.templatesDirectory
        let destURL = ReceiptTemplatePaths.customTemplateURL(for: prefix)
        do {
            try fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: destURL.path) {
                try fileManager.removeItem(at: destURL)
            }
            try data.write(to: destURL, options: .atomic)
        } catch {
            throw StoreError.writeFailed(underlying: error)
        }

        let originalFilename = sourceURL.lastPathComponent
        let importedAt = Date()
        userDefaults.set(originalFilename, forKey: filenameKey(for: prefix))
        userDefaults.set(importedAt, forKey: importedAtKey(for: prefix))

        return ImportedMetadata(
            url: destURL,
            originalFilename: originalFilename,
            importedAt: importedAt,
            fileSize: data.count
        )
    }

    /// Deletes the per-org imported template and clears its metadata.
    /// After this, the resolver falls back to the bundled template.
    func deleteTemplate() throws {
        guard let prefix = prefixProvider(), !prefix.isEmpty else {
            throw StoreError.noActiveOrganization
        }

        let url = ReceiptTemplatePaths.customTemplateURL(for: prefix)
        if fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
            } catch {
                throw StoreError.deleteFailed(underlying: error)
            }
        }
        userDefaults.removeObject(forKey: filenameKey(for: prefix))
        userDefaults.removeObject(forKey: importedAtKey(for: prefix))
    }

    /// Returns metadata for the currently-imported template, or `nil`
    /// when the active org is using the bundled fallback.
    func currentMetadata() -> ImportedMetadata? {
        guard let prefix = prefixProvider(), !prefix.isEmpty else { return nil }
        let url = ReceiptTemplatePaths.customTemplateURL(for: prefix)
        guard fileManager.fileExists(atPath: url.path) else { return nil }

        let attrs = try? fileManager.attributesOfItem(atPath: url.path)
        let size = (attrs?[.size] as? NSNumber)?.intValue ?? 0
        let filename = userDefaults.string(forKey: filenameKey(for: prefix)) ?? url.lastPathComponent
        let importedAt = userDefaults.object(forKey: importedAtKey(for: prefix)) as? Date ?? Date()

        return ImportedMetadata(
            url: url,
            originalFilename: filename,
            importedAt: importedAt,
            fileSize: size
        )
    }

    // MARK: - UserDefaults keys
    private func filenameKey(for prefix: String) -> String { "\(prefix)_receiptTemplateFilename" }
    private func importedAtKey(for prefix: String) -> String { "\(prefix)_receiptTemplateImportedAt" }
}
