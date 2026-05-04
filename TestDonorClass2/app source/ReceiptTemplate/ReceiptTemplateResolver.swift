import Foundation

/// Decides which PDF template to use for the currently active
/// organization.
///
/// Resolution order:
///   1. Per-org imported template at `Documents/ReceiptTemplates/<prefix>.pdf`
///   2. Bundled fallback (`Chaye_Olam_Receipt.pdf`)
///
/// Always returns a URL — callers don't need to handle nil. If the
/// bundled fallback is somehow missing, that is a programmer error
/// (the build is broken) and the resolver will trap.
protocol ReceiptTemplateResolver {
    func templateURL() -> URL
}

/// Production implementation that reads the current org from
/// `ApplicationData.shared` and the bundled fallback from the main
/// bundle.
struct DefaultReceiptTemplateResolver: ReceiptTemplateResolver {
    let bundle: Bundle
    let bundledResourceName: String
    let bundledExtension: String
    private let prefixProvider: () -> String?
    private let fileManager: FileManager

    init(bundle: Bundle = .main,
         bundledResourceName: String = "Chaye_Olam_Receipt",
         bundledExtension: String = "pdf",
         prefixProvider: @escaping () -> String? = ReceiptTemplatePaths.currentOrgPrefix,
         fileManager: FileManager = .default) {
        self.bundle = bundle
        self.bundledResourceName = bundledResourceName
        self.bundledExtension = bundledExtension
        self.prefixProvider = prefixProvider
        self.fileManager = fileManager
    }

    func templateURL() -> URL {
        if let customURL = customTemplateURLIfExists() {
            return customURL
        }
        guard let url = bundle.url(forResource: bundledResourceName,
                                   withExtension: bundledExtension) else {
            preconditionFailure(
                "Bundled template '\(bundledResourceName).\(bundledExtension)' is missing from the app bundle."
            )
        }
        return url
    }

    private func customTemplateURLIfExists() -> URL? {
        guard let prefix = prefixProvider(), !prefix.isEmpty else { return nil }
        let url = ReceiptTemplatePaths.customTemplateURL(for: prefix)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }
}
