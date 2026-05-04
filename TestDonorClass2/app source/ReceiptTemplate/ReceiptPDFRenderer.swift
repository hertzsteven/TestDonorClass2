import Foundation
import PDFKit

/// Loads the active receipt template PDF and stamps a set of values
/// into its named AcroForm fields, returning the filled PDF as `Data`.
///
/// This service has a single responsibility: PDF form-fill. It does
/// not print, does not present UI, and does not know where the values
/// came from. It also doesn't know whether the template is the bundled
/// fallback or a per-org imported one — the `ReceiptTemplateResolver`
/// answers that question.
struct ReceiptPDFRenderer {
    enum RenderError: Error, LocalizedError {
        case templateUnreadable(URL)
        case serializationFailed

        var errorDescription: String? {
            switch self {
            case .templateUnreadable(let url):
                return "PDF template '\(url.lastPathComponent)' could not be opened by PDFKit."
            case .serializationFailed:
                return "PDFKit failed to serialize the filled PDF back to data."
            }
        }
    }

    let resolver: ReceiptTemplateResolver

    init(resolver: ReceiptTemplateResolver = DefaultReceiptTemplateResolver()) {
        self.resolver = resolver
    }

    /// Returns a freshly filled copy of the template PDF as `Data`.
    /// Each call produces an independent `Data` blob — the source
    /// template on disk is never modified.
    func render(values: ReceiptFieldValues) throws -> Data {
        let url = resolver.templateURL()

        guard let document = PDFDocument(url: url) else {
            throw RenderError.templateUnreadable(url)
        }

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            for annotation in page.annotations {
                guard
                    let fieldName = annotation.fieldName,
                    !fieldName.isEmpty,
                    let newValue = values.value(forFieldName: fieldName)
                else {
                    continue
                }
                annotation.widgetStringValue = newValue
            }
        }

        guard let data = document.dataRepresentation() else {
            throw RenderError.serializationFailed
        }
        return data
    }
}
