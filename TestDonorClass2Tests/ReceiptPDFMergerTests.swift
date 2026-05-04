//
//  ReceiptPDFMergerTests.swift
//  TestDonorClass2Tests
//

import PDFKit
import Testing
import UIKit
@testable import TestDonorClass2

struct ReceiptPDFMergerTests {

    @Test func mergeConcatenatesPageCounts() throws {
        let doc1 = try makeOnePageBlankPDF()
        let doc2 = try makeOnePageBlankPDF()
        let merged = ReceiptPDFMerger.merge(documents: [doc1, doc2])
        #expect(merged?.pageCount == 2)
    }

    @Test func mergeEmptyReturnsNil() {
        #expect(ReceiptPDFMerger.merge(documents: []) == nil)
    }

    private func makeOnePageBlankPDF() throws -> PDFDocument {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("merge-test-\(UUID().uuidString).pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        try renderer.writePDF(to: url) { ctx in
            ctx.beginPage()
        }
        let doc = try #require(PDFDocument(url: url))
        return doc
    }
}
