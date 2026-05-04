import Foundation

/// How the app builds the PDF sent to the printer for donation receipts.
/// Stored per organization (database prefix) in `UserDefaults`.
enum ReceiptOutputMode: String, CaseIterable, Identifiable, Sendable {
    /// Current `UIGraphicsPDFRenderer` layout on a blank page.
    case drawnProgrammatic = "drawnProgrammatic"
    /// Fill AcroForm fields on the resolved template PDF (`ReceiptPDFRenderer`).
    case templateFormFilled = "templateFormFilled"
    /// Blank page; variable text drawn at widget rects read from the template PDF (pre-printed stock).
    case preprintedVariableOnly = "preprintedVariableOnly"

    var id: String { rawValue }

    /// Short label for pickers.
    var pickerTitle: String {
        switch self {
        case .drawnProgrammatic:
            return "Drawn (blank PDF)"
        case .templateFormFilled:
            return "Template (PDF form fields)"
        case .preprintedVariableOnly:
            return "Pre-printed paper (fields only)"
        }
    }
}
