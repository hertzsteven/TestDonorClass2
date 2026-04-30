import Foundation
import PDFKit

/// Loads the bundled receipt template PDF and stamps a set of values
/// into its named AcroForm fields, returning the filled PDF as `Data`.
///
/// This service has a single responsibility: PDF form-fill. It does not
/// print, does not present UI, and does not know where the values came
/// from. That separation makes it easy to mock in tests and reuse later
/// when we replace the bundled prototype with a user-imported template.
struct ReceiptPDFRenderer {
    enum RenderError: Error, LocalizedError {
        case templateNotFound(name: String)
        case templateUnreadable(name: String)
        case serializationFailed

        var errorDescription: String? {
            switch self {
            case .templateNotFound(let name):
                return "PDF template '\(name).pdf' was not found in the app bundle. Make sure the file is added to the target."
            case .templateUnreadable(let name):
                return "PDF template '\(name).pdf' could not be opened by PDFKit."
            case .serializationFailed:
                return "PDFKit failed to serialize the filled PDF back to data."
            }
        }
    }

    let templateResourceName: String
    let bundle: Bundle

    init(templateResourceName: String = "Chaye_Olam_Receipt",
         bundle: Bundle = .main) {
        self.templateResourceName = templateResourceName
        self.bundle = bundle
    }

    /// Returns a freshly filled copy of the template PDF as `Data`.
    /// Each call produces an independent `Data` blob — the bundled
    /// template on disk is never modified.
    func render(values: ReceiptFieldValues) throws -> Data {
        guard let url = bundle.url(forResource: templateResourceName, withExtension: "pdf") else {
            throw RenderError.templateNotFound(name: templateResourceName)
        }

        guard let document = PDFDocument(url: url) else {
            throw RenderError.templateUnreadable(name: templateResourceName)
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
