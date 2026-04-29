import SwiftUI

/// PoC screen: tap the button → render the next mock receipt → show it
/// in an embedded PDF preview. No printing here yet (Step 4 will add
/// AirPrint).
struct ReceiptMockView: View {
    @State private var viewModel = ReceiptMockViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Button("Generate Next Mock Receipt", systemImage: "doc.text.fill") {
                viewModel.generateNext()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

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
                    description: Text("Press the button above to fill the prototype PDF with mock data and preview the result.")
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
