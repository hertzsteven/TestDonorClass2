import Foundation

/// Centralizes the on-disk layout for per-organization receipt PDF
/// templates. Keeping path/prefix derivation in one place avoids subtle
/// drift between the store, the resolver, and any future migrations.
enum ReceiptTemplatePaths {
    /// Folder name inside `Documents/` that holds all per-org templates.
    static let folderName = "ReceiptTemplates"

    /// The directory URL for storing imported templates. Callers should
    /// create it before writing.
    static var templatesDirectory: URL {
        URL.documentsDirectory.appending(path: folderName, directoryHint: .isDirectory)
    }

    /// URL for a given organization's custom template file.
    static func customTemplateURL(for prefix: String) -> URL {
        templatesDirectory.appending(path: "\(prefix).pdf")
    }

    /// Resolves the prefix for the currently active organization, or
    /// `nil` when no database has been selected yet.
    ///
    /// Mirrors the prefix logic used by `OrganizationSettingsManager` so
    /// org-scoped storage stays consistent across features.
    static func currentOrgPrefix() -> String? {
        guard let db = ApplicationData.shared.selectedDatabase, !db.isEmpty else {
            return nil
        }
        return (db as NSString).deletingPathExtension
    }
}
