import PDFKit
import SwiftUI

/// Bridge that lets a SwiftUI view embed a PDFKit `PDFView`. PDFKit is a
/// UIKit framework — there is no pure-SwiftUI equivalent for displaying
/// a PDF, so this small `UIViewRepresentable` is the standard,
/// Apple-sanctioned way to drop a PDF into a SwiftUI hierarchy.
struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        return view
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = PDFDocument(data: data)
    }
}
