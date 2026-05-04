//
//  ReceiptActionBarView.swift
//  TestDonorClass2
//
//  Bottom action bar for the Receipts screen. Hosts deselect / test
//  print / refresh / max-per-print stepper / print-all controls.
//

import SwiftUI

struct ReceiptActionBarView: View {
    let status: ReceiptStatus
    let hasItems: Bool
    let selectedCount: Int
    let maxReceiptsPerPrint: Int

    let onDeselectAll: () -> Void
    let onTestPrint: () -> Void
    let onRefresh: () -> Void
    let onChangeMax: (Int) -> Void
    let onPrintAll: () -> Void
    let onMarkSelectedPrinted: () -> Void

    var body: some View {
        HStack {
            if status == .requested && selectedCount > 0 {
                Button(action: onDeselectAll) {
                    Label("Deselect All", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if status == .requested {
                Button(action: onTestPrint) {
                    Label("Test Print", systemImage: "checkmark.circle")
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.orange)
            }

            Button(action: onRefresh) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)

            if hasItems && status == .requested {
                MaxReceiptsStepperView(
                    value: maxReceiptsPerPrint,
                    onChange: onChangeMax
                )

                if selectedCount > 0 {
                    Button(action: onMarkSelectedPrinted) {
                        Label(
                            "Mark Printed (\(selectedCount))",
                            systemImage: "checkmark.circle.fill"
                        )
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                }

                Button(action: onPrintAll) {
                    if selectedCount == 0 {
                        Label("Print All", systemImage: "printer")
                            .padding(.horizontal, 10)
                    } else {
                        Label("Print Selected (\(selectedCount))", systemImage: "printer")
                            .padding(.horizontal, 10)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
