//
//  ReceiptPrintingService+Async.swift
//  TestDonorClass2
//
//  Async/await wrappers around the callback-based ReceiptPrintingService.
//  Lets call sites use modern Swift concurrency instead of completion
//  handlers, eliminating the need for a custom TaskCompletionSource.
//

import Foundation

extension ReceiptPrintingService {
    /// Prints a single receipt and returns whether the user completed (true)
    /// or cancelled (false) the print dialog.
    @MainActor
    func printReceipt(
        for donation: DonationInfo,
        mode: ReceiptOutputMode = .drawnProgrammatic
    ) async -> Bool {
        await withCheckedContinuation { continuation in
            printReceipt(for: donation, mode: mode) { success in
                continuation.resume(returning: success)
            }
        }
    }

    /// Prints multiple receipts in one print job. Returns true if the user
    /// completed the dialog, false if cancelled.
    @MainActor
    func printReceipts(
        for donations: [DonationInfo],
        mode: ReceiptOutputMode = .drawnProgrammatic
    ) async -> Bool {
        await withCheckedContinuation { continuation in
            printReceipts(for: donations, mode: mode) { success in
                continuation.resume(returning: success)
            }
        }
    }
}
