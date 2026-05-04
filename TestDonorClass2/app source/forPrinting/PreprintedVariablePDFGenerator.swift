import Foundation
import PDFKit
import UIKit

/// Renders variable receipt text onto a blank letter page at widget rectangles
/// read from the active template PDF (for pre-printed letterhead).
struct PreprintedVariablePDFGenerator {
    enum GeneratorError: Error, LocalizedError {
        case templateUnreadable(URL)
        case noPages
        case serializationFailed

        var errorDescription: String? {
            switch self {
            case .templateUnreadable(let url):
                return "Could not open template at \(url.lastPathComponent) for field layout."
            case .noPages:
                return "The receipt template PDF has no pages."
            case .serializationFailed:
                return "Failed to serialize the pre-printed variable PDF."
            }
        }
    }

    private let resolver: ReceiptTemplateResolver

    init(resolver: ReceiptTemplateResolver = DefaultReceiptTemplateResolver()) {
        self.resolver = resolver
    }

    func generatePdfData(values: ReceiptFieldValues) throws -> Data {
        let url = resolver.templateURL()
        guard let templateDoc = PDFDocument(url: url) else {
            throw GeneratorError.templateUnreadable(url)
        }
        guard let referencePage = templateDoc.page(at: 0) else {
            throw GeneratorError.noPages
        }

        let mediaBox = referencePage.bounds(for: .mediaBox)
        let pageSize = CGSize(width: mediaBox.width, height: mediaBox.height)

        var fieldRects: [String: CGRect] = [:]
        for index in 0..<templateDoc.pageCount {
            guard let page = templateDoc.page(at: index) else { continue }
            for annotation in page.annotations {
                guard
                    let name = annotation.fieldName,
                    !name.isEmpty,
                    ReceiptTemplateValidator.expectedFields.contains(name)
                else { continue }
                if fieldRects[name] == nil {
                    fieldRects[name] = annotation.bounds
                }
            }
        }

        let outURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("preprinted-vars-\(UUID().uuidString).pdf")

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        try renderer.writePDF(to: outURL) { context in
            context.beginPage()
            for fieldName in ReceiptTemplateValidator.expectedFields {
                guard let pdfRect = fieldRects[fieldName],
                      let text = values.value(forFieldName: fieldName),
                      !text.isEmpty
                else { continue }

                let uiRect = Self.pdfRectToUIKitRect(pdfRect, pageHeight: pageSize.height)
                let attributes = Self.attributes(forFieldName: fieldName)

                context.cgContext.saveGState()
                let clipPath = UIBezierPath(rect: uiRect)
                clipPath.addClip()
                (text as NSString).draw(
                    with: uiRect,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
                context.cgContext.restoreGState()
            }
        }

        let data = try Data(contentsOf: outURL)
        try? FileManager.default.removeItem(at: outURL)
        guard !data.isEmpty else {
            throw GeneratorError.serializationFailed
        }
        return data
    }

    /// PDF page space uses a bottom-left origin; `UIGraphicsPDFRenderer` drawing uses top-left.
    private static func pdfRectToUIKitRect(_ pdfRect: CGRect, pageHeight: CGFloat) -> CGRect {
        CGRect(
            x: pdfRect.origin.x,
            y: pageHeight - pdfRect.origin.y - pdfRect.height,
            width: pdfRect.width,
            height: pdfRect.height
        )
    }

    private static func attributes(forFieldName name: String) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .left

        let fontSize: CGFloat
        switch name {
        case "letter_body":
            fontSize = 9
        case "donation_amount", "receipt_number":
            fontSize = 11
        default:
            fontSize = 10
        }

        return [
            .font: UIFont.systemFont(ofSize: fontSize),
            .paragraphStyle: paragraph,
        ]
    }
}
