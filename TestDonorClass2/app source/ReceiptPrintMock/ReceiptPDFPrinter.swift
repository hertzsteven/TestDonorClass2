import Foundation
import UIKit

/// Hands a finished PDF blob to iOS's AirPrint controller.
///
/// `UIPrintInteractionController` is a UIKit-only, callback-based API.
/// This service wraps it behind a modern async surface so the view model
/// can `await` the result without juggling completion handlers.
///
/// The struct itself is nonisolated (it has no stored state); only the
/// `print` method is `@MainActor` because it touches the shared UIKit
/// print controller.
struct ReceiptPDFPrinter {
    enum PrintError: Error, LocalizedError {
        case temporaryFileWriteFailed
        case userCancelled
        case systemReported(Error)

        var errorDescription: String? {
            switch self {
            case .temporaryFileWriteFailed:
                return "Could not stage the PDF for printing."
            case .userCancelled:
                return "Print was cancelled."
            case .systemReported(let underlying):
                return "Printing failed: \(underlying.localizedDescription)"
            }
        }
    }

    /// Presents the AirPrint sheet for the given PDF blob. Returns when
    /// the user dismisses the sheet successfully. Throws on cancellation
    /// or system error.
    @MainActor
    func print(pdfData: Data, jobName: String) async throws {
        let url = try writeTemporaryPDF(pdfData)

        let controller = UIPrintInteractionController.shared
        controller.printingItem = url

        let info = UIPrintInfo.printInfo()
        info.outputType = .general
        info.orientation = .portrait
        info.jobName = jobName
        controller.printInfo = info

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            controller.present(animated: true) { _, completed, error in
                if let error {
                    continuation.resume(throwing: PrintError.systemReported(error))
                } else if completed {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: PrintError.userCancelled)
                }
            }
        }
    }

    private func writeTemporaryPDF(_ data: Data) throws -> URL {
        let url = URL.temporaryDirectory
            .appending(path: "receipt-\(UUID().uuidString).pdf")
        do {
            try data.write(to: url)
            return url
        } catch {
            throw PrintError.temporaryFileWriteFailed
        }
    }
}
