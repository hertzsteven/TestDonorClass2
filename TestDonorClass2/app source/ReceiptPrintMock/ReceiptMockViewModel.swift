import Foundation

/// Coordinates between the mock dataset, the PDF renderer, and the
/// printer for the PoC view. Holds only what the UI needs to display:
/// the latest filled PDF, which mock it represents, an in-flight print
/// flag, and any error string.
///
/// Stays narrowly scoped per the project's view-model rules: it does
/// not own data persistence or business logic — those are other types'
/// responsibilities.
@MainActor
@Observable
final class ReceiptMockViewModel {
    private(set) var currentPDFData: Data?
    private(set) var currentDonorName: String?
    private(set) var currentMockNumber: Int?
    private(set) var lastError: String?
    private(set) var isPrinting: Bool = false

    private var nextIndex: Int = 0
    private let mockData: [ReceiptFieldValues]
    private let renderer: ReceiptPDFRenderer
    private let printer: ReceiptPDFPrinter

    init(mockData: [ReceiptFieldValues] = ReceiptMockData.threeReceipts,
         renderer: ReceiptPDFRenderer = ReceiptPDFRenderer(),
         printer: ReceiptPDFPrinter = ReceiptPDFPrinter()) {
        self.mockData = mockData
        self.renderer = renderer
        self.printer = printer
    }

    var totalMockCount: Int { mockData.count }

    var canPrint: Bool { currentPDFData != nil && !isPrinting }

    /// Renders the next mock receipt in the cycle, advancing the
    /// rotating index. After the last mock, wraps around to the first.
    func generateNext() {
        guard !mockData.isEmpty else { return }

        let values = mockData[nextIndex]
        do {
            currentPDFData = try renderer.render(values: values)
            currentDonorName = values.donorName
            currentMockNumber = nextIndex + 1
            lastError = nil
            nextIndex = (nextIndex + 1) % mockData.count
        } catch {
            currentPDFData = nil
            currentDonorName = nil
            currentMockNumber = nil
            lastError = error.localizedDescription
        }
    }

    /// Sends the currently displayed PDF to AirPrint. No-op if there
    /// isn't one. Surfaces user cancellation and system errors via
    /// `lastError`.
    func printCurrentReceipt() async {
        guard let data = currentPDFData, !isPrinting else { return }

        isPrinting = true
        defer { isPrinting = false }

        let jobName = "Donation Receipt — \(currentDonorName ?? "Mock")"
        do {
            try await printer.print(pdfData: data, jobName: jobName)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}
