import SwiftUI

/// PoC screen: tap *Generate* to render the next mock receipt → shown
/// in an embedded PDF preview. Tap *Print* to send the currently shown
/// PDF to AirPrint.
struct ReceiptMockView: View {
    @State private var viewModel = ReceiptMockViewModel()

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Generate Next", systemImage: "doc.text.fill") {
                    viewModel.generateNext()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Print", systemImage: "printer.fill") {
                    Task { await viewModel.printCurrentReceipt() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canPrint)
            }

            if let mockNumber = viewModel.currentMockNumber,
               let donorName = viewModel.currentDonorName {
                Text("Mock #\(mockNumber) of \(viewModel.totalMockCount) — \(donorName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let error = viewModel.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            if let data = viewModel.currentPDFData {
                PDFKitView(data: data)
                    .clipShape(.rect(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.quaternary, lineWidth: 1)
                    )
            } else {
                ContentUnavailableView(
                    "Tap to Generate",
                    systemImage: "doc.text",
                    description: Text("Press *Generate Next* to fill the template PDF with mock data and preview the result.")
                )
            }
        }
        .padding()
        .navigationTitle("Receipt PoC")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ReceiptMockView()
    }
}
