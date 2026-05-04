import Foundation
import PDFKit

/// Inspects a candidate receipt template PDF and reports which AcroForm
/// fields it contains compared to the schema the app expects.
///
/// Validation is *loose*: missing fields produce a warning so users can
/// intentionally drop sections (e.g. omit the letter block). The render
/// step will simply skip any field the PDF doesn't have.
struct ReceiptTemplateValidator {
    enum ValidationError: Error, LocalizedError {
        case notAPDF(URL)

        var errorDescription: String? {
            switch self {
            case .notAPDF(let url):
                return "\(url.lastPathComponent) doesn't appear to be a valid PDF."
            }
        }
    }

    struct Report: Equatable {
        let foundFields: Set<String>
        /// Expected by the app but not present in this PDF.
        let missingFields: [String]
        /// Present in the PDF but not part of the app's schema.
        /// They are harmless — the renderer just won't fill them.
        let extraFields: [String]

        var hasAllExpectedFields: Bool { missingFields.isEmpty }
    }

    /// The 8 field names the app fills today, listed in receipt order
    /// for predictable UI display.
    static let expectedFields: [String] = [
        "letter_date",
        "letter_greeting",
        "letter_body",
        "donor_name",
        "donor_address_block",
        "receipt_number",
        "receipt_date",
        "donation_amount"
    ]

    func validate(pdfAt url: URL) throws -> Report {
        guard let document = PDFDocument(url: url) else {
            throw ValidationError.notAPDF(url)
        }

        var found = Set<String>()
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            for annotation in page.annotations {
                if let name = annotation.fieldName, !name.isEmpty {
                    found.insert(name)
                }
            }
        }

        let expected = Set(Self.expectedFields)
        let missing = Self.expectedFields.filter { !found.contains($0) }
        let extra = found.subtracting(expected).sorted()

        return Report(foundFields: found, missingFields: missing, extraFields: extra)
    }
}
