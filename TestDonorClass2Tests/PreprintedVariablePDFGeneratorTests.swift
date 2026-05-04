//
//  PreprintedVariablePDFGeneratorTests.swift
//  TestDonorClass2Tests
//

import Foundation
import Testing
@testable import TestDonorClass2

private struct UnreadableTemplateResolver: ReceiptTemplateResolver {
    func templateURL() -> URL {
        URL(fileURLWithPath: "/nonexistent/receipt-template-\(UUID().uuidString).pdf")
    }
}

struct PreprintedVariablePDFGeneratorTests {

    @Test func throwsWhenTemplateUnreadable() {
        #expect(throws: PreprintedVariablePDFGenerator.GeneratorError.self) {
            try PreprintedVariablePDFGenerator(resolver: UnreadableTemplateResolver())
                .generatePdfData(values: ReceiptFieldValues())
        }
    }
}
