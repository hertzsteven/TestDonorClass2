//
//  BarcodeScannerSheetView.swift
//  TestDonorClass2
//

import SwiftUI

struct BarcodeScannerSheetView: View {
    @Binding var scannedCode: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            BarcodeScannerView(scannedCode: $scannedCode)

            Button("Cancel", systemImage: "xmark") {
                dismiss()
            }
            .padding()
            .background(.ultraThinMaterial, in: .circle)
        }
        .interactiveDismissDisabled()
    }
}
