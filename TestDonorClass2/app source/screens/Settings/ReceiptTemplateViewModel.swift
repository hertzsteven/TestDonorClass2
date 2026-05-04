import Foundation

/// Coordinates between the file picker, the template store, the
/// validator, and the Settings UI. Holds derived display state — never
/// raw I/O — per the project's view-model rules.
@MainActor
@Observable
final class ReceiptTemplateViewModel {
    enum Status: Equatable {
        case loading
        case usingBundled
        case usingCustom(filename: String, importedAt: Date, fileSize: Int)
    }

    private(set) var status: Status = .loading
    private(set) var validationReport: ReceiptTemplateValidator.Report?
    var lastErrorMessage: String?

    private let store: ReceiptTemplateStore
    private let validator: ReceiptTemplateValidator
    private let resolver: ReceiptTemplateResolver

    init(store: ReceiptTemplateStore = ReceiptTemplateStore(),
         validator: ReceiptTemplateValidator = ReceiptTemplateValidator(),
         resolver: ReceiptTemplateResolver = DefaultReceiptTemplateResolver()) {
        self.store = store
        self.validator = validator
        self.resolver = resolver
    }

    /// Refreshes state from disk. Safe to call from `.task`/`onAppear`.
    func refresh() {
        if let metadata = store.currentMetadata() {
            status = .usingCustom(
                filename: metadata.originalFilename,
                importedAt: metadata.importedAt,
                fileSize: metadata.fileSize
            )
            validationReport = try? validator.validate(pdfAt: metadata.url)
        } else {
            status = .usingBundled
            validationReport = try? validator.validate(pdfAt: resolver.templateURL())
        }
        lastErrorMessage = nil
    }

    /// Imports the user-picked PDF, then refreshes state.
    func importPDF(from sourceURL: URL) {
        do {
            try store.importTemplate(from: sourceURL)
            refresh()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    /// Deletes the custom template; resolver will fall back to bundled.
    func deleteCustomTemplate() {
        do {
            try store.deleteTemplate()
            refresh()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    /// PDF data of the currently-resolved template, for previewing.
    var currentTemplatePDFData: Data? {
        try? Data(contentsOf: resolver.templateURL())
    }
}
