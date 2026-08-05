//
//  NCOADeletionImportView.swift
//  TestDonorClass2
//
//  Import a National Change of Address delete file, listing donors who moved
//  with no forwarding address. Verified donors are flagged Bad Address so mail
//  stops. No donor, address or donation is ever removed.
//

import SwiftUI
import UniformTypeIdentifiers

struct NCOADeletionImportView: View {

    @State private var viewModel: NCOADeletionImportViewModel
    @State private var isShowingFileImporter = false

    init() {
        do {
            _viewModel = State(
                wrappedValue: NCOADeletionImportViewModel(deletionService: try NCOADeletionService())
            )
        } catch {
            fatalError("Failed to initialize repositories for NCOADeletionImportView: \(error)")
        }
    }

    var body: some View {
        @Bindable var boundViewModel = viewModel

        Form {
            Section {
                Button("Choose NCOA delete file", systemImage: "doc.badge.plus") {
                    isShowingFileImporter = true
                }
                .disabled(viewModel.isWorking)

                if viewModel.isWorking {
                    ProgressView()
                }
            } footer: {
                Text("Nothing changes until you tap Apply. A donor is only flagged when the address on file is the one the mailing service could not deliver to. Donors, addresses and donation history are kept; only Mail Status changes.")
            }

            if let summary = viewModel.summary {
                NCOADeletionSummarySectionView(summary: summary, fileName: viewModel.fileName)

                if let applyResult = viewModel.applyResult {
                    NCOAApplyResultSectionView(result: applyResult)
                }

                if summary.applyableCount > 0 {
                    Section {
                        Button("Flag \(summary.applyableCount) donors as Bad Address") {
                            Task { await viewModel.apply() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.canApply)
                    }
                }

                ForEach(NCOADeletionOutcome.displayOrder) { outcome in
                    NCOADeletionOutcomeSectionView(
                        outcome: outcome,
                        items: viewModel.items(for: outcome)
                    )
                }
            }
        }
        .navigationTitle("NCOA Undeliverable")
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                Task { await viewModel.loadPreview(from: url) }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
        .alert("Import failed", isPresented: $boundViewModel.isShowingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
