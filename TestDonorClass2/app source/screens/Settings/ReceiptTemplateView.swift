import SwiftUI
import UniformTypeIdentifiers

/// Per-organization receipt template management screen, pushed from
/// SettingsView. Lets the user import a custom PDF, see validation
/// results, preview the current template, and reset to the bundled
/// default.
struct ReceiptTemplateView: View {
    @State private var viewModel = ReceiptTemplateViewModel()
    @State private var isImporterPresented = false
    @State private var isPreviewPresented = false
    @State private var isDeleteConfirmationPresented = false

    var body: some View {
        Form {
            Section("Current Template") {
                ReceiptTemplateStatusRow(status: viewModel.status)
            }

            if let report = viewModel.validationReport {
                Section("Field Validation") {
                    ReceiptTemplateValidationRows(report: report)
                }
            }

            if let error = viewModel.lastErrorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            Section("Actions") {
                Button("Import PDF…", systemImage: "square.and.arrow.down") {
                    isImporterPresented = true
                }

                Button("Preview Current Template", systemImage: "eye") {
                    isPreviewPresented = true
                }
                .disabled(viewModel.currentTemplatePDFData == nil)

                if case .usingCustom = viewModel.status {
                    Button("Reset to Bundled Default",
                           systemImage: "arrow.uturn.backward",
                           role: .destructive) {
                        isDeleteConfirmationPresented = true
                    }
                }
            }
        }
        .navigationTitle("Receipt Template")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.refresh() }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                viewModel.importPDF(from: url)
            case .failure(let error):
                viewModel.lastErrorMessage = error.localizedDescription
            }
        }
        .sheet(isPresented: $isPreviewPresented) {
            ReceiptTemplatePreviewSheet(
                pdfData: viewModel.currentTemplatePDFData,
                onDismiss: { isPreviewPresented = false }
            )
            .interactiveDismissDisabled()
        }
        .confirmationDialog(
            "Reset to Bundled Template?",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                viewModel.deleteCustomTemplate()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your imported PDF will be removed and the app will use the bundled default template.")
        }
    }
}

// MARK: - Subviews

private struct ReceiptTemplateStatusRow: View {
    let status: ReceiptTemplateViewModel.Status

    var body: some View {
        switch status {
        case .loading:
            ProgressView().controlSize(.small)
        case .usingBundled:
            Label("Using bundled default", systemImage: "doc.fill")
                .foregroundStyle(.secondary)
        case .usingCustom(let filename, let importedAt, let fileSize):
            ReceiptTemplateCustomStatusRow(
                filename: filename,
                importedAt: importedAt,
                fileSize: fileSize
            )
        }
    }
}

private struct ReceiptTemplateCustomStatusRow: View {
    let filename: String
    let importedAt: Date
    let fileSize: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Custom template imported", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
            Text(filename)
                .font(.subheadline)
            Text("Imported \(importedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(Int64(fileSize), format: .byteCount(style: .file))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ReceiptTemplateValidationRows: View {
    let report: ReceiptTemplateValidator.Report

    var body: some View {
        if report.hasAllExpectedFields {
            Label(
                "All \(ReceiptTemplateValidator.expectedFields.count) expected fields present",
                systemImage: "checkmark.circle.fill"
            )
            .foregroundStyle(.green)
        } else {
            Label("\(report.missingFields.count) field(s) missing",
                  systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            ForEach(report.missingFields, id: \.self) { name in
                Text("— \(name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        if !report.extraFields.isEmpty {
            Label("\(report.extraFields.count) extra field(s) ignored",
                  systemImage: "info.circle")
                .foregroundStyle(.secondary)
            ForEach(report.extraFields, id: \.self) { name in
                Text("— \(name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct ReceiptTemplatePreviewSheet: View {
    let pdfData: Data?
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if let pdfData {
                    PDFKitView(data: pdfData)
                } else {
                    ContentUnavailableView(
                        "No Template Available",
                        systemImage: "doc.questionmark"
                    )
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDismiss)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReceiptTemplateView()
    }
}
