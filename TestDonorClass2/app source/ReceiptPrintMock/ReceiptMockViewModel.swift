import Foundation

/// Coordinates between the mock dataset and the PDF renderer for the
/// PoC view. Holds only what the UI needs to display: the latest filled
/// PDF, which mock it represents, and any error string.
///
/// Stays narrowly scoped per the project's view-model rules: it does
/// not own data persistence, business logic, or printing — those are
/// other types' responsibilities.
@MainActor
@Observable
final class ReceiptMockViewModel {
    private(set) var currentPDFData: Data?
    private(set) var currentDonorName: String?
    private(set) var currentMockNumber: Int?
    private(set) var lastError: String?

    private var nextIndex: Int = 0
    private let mockData: [ReceiptFieldValues]
    private let renderer: ReceiptPDFRenderer

    init(mockData: [ReceiptFieldValues] = ReceiptMockData.threeReceipts,
         renderer: ReceiptPDFRenderer = ReceiptPDFRenderer()) {
        self.mockData = mockData
        self.renderer = renderer
    }

    var totalMockCount: Int { mockData.count }

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
}
