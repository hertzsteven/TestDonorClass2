//
//  PrintReceiptSheetView.swift
//  TestDonorClass2
//
//  Modal sheet that drives the batch-print flow. Delegates all I/O and
//  status updates to ReceiptService and reports the final outcome to
//  the caller via a single callback.
//

import SwiftUI

struct PrintReceiptSheetView: View {
    let receipts: [ReceiptItem]
    let onCompletion: (PrintBatchOutcome) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isPrinting = false
    @State private var statusMessage = ""
    @State private var assignedNumbers: [String] = []

    private let service: ReceiptService

    init(
        receipts: [ReceiptItem],
        service: ReceiptService,
        onCompletion: @escaping (PrintBatchOutcome) -> Void
    ) {
        self.receipts = receipts
        self.service = service
        self.onCompletion = onCompletion
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "printer.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Print Receipts")
                .font(.title)
                .bold()

            if !assignedNumbers.isEmpty {
                AssignedReceiptNumbersBanner(numbers: assignedNumbers)
            } else if isPrinting {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                Text(statusMessage)
                    .foregroundStyle(.secondary)
            } else {
                Text("Ready to print \(receipts.count) receipt(s)")
                    .foregroundStyle(.secondary)
                Text("All receipts will be combined into a single PDF")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)

                Spacer()

                Button {
                    Task { await startBatchPrinting() }
                } label: {
                    Text("Print Now")
                        .padding(.horizontal, 20)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isPrinting)
            }
            .padding()
        }
        .padding()
        .frame(minWidth: 300, minHeight: 400)
    }

    private func startBatchPrinting() async {
        isPrinting = true
        statusMessage = "Generating PDF…"

        let result = await service.batchPrint(receipts)

        statusMessage = "Done"
        isPrinting = false

        let outcome = PrintBatchOutcome(
            printed: result.printed,
            cancelled: result.cancelled,
            failed: result.failed,
            totalRequested: receipts.count,
            receiptNumbers: result.receiptNumbers
        )

        // Briefly surface the freshly generated receipt numbers so the user
        // can confirm numbering worked, then auto-dismiss.
        if !result.receiptNumbers.isEmpty {
            withAnimation { assignedNumbers = result.receiptNumbers }
            try? await Task.sleep(for: .seconds(3))
        }

        dismiss()
        onCompletion(outcome)
    }
}

/// Transient confirmation banner that lists the receipt numbers assigned
/// during a batch print. Shown for a few seconds, then dismissed.
private struct AssignedReceiptNumbersBanner: View {
    let numbers: [String]

    var body: some View {
        VStack(spacing: 8) {
            Label("Receipt numbers assigned", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
                .bold()

            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(numbers, id: \.self) { number in
                        Text(number)
                            .font(.body.monospaced())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 160)
            .scrollIndicators(.hidden)
        }
        .padding()
        .background(.green.opacity(0.12), in: .rect(cornerRadius: 12))
        .transition(.opacity)
    }
}

/// Result of a batch-print attempt, surfaced to the parent view so it
/// can display an appropriate alert.
struct PrintBatchOutcome {
    let printed: Int
    let cancelled: Int
    let failed: Int
    let totalRequested: Int
    var receiptNumbers: [String] = []

    var wasCancelled: Bool { cancelled > 0 && printed == 0 && failed == 0 }
}
