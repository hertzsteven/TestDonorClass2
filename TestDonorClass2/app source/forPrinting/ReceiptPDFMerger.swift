import Foundation
import PDFKit

/// Appends every page from each source document into one multi-page `PDFDocument`.
enum ReceiptPDFMerger {

    static func merge(documents: [PDFDocument]) -> PDFDocument? {
        guard !documents.isEmpty else { return nil }
        let merged = PDFDocument()
        for doc in documents {
            for index in 0..<doc.pageCount {
                guard let page = doc.page(at: index) else { continue }
                guard let copied = page.copy() as? PDFPage else { continue }
                merged.insert(copied, at: merged.pageCount)
            }
        }
        return merged.pageCount > 0 ? merged : nil
    }
}
