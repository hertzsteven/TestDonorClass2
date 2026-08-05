//
//  NCOAImportView.swift
//  TestDonorClass2
//
//  Import a National Change of Address update file. Every row is classified and
//  shown before anything is written, and only rows whose address on file matches
//  the old address in the file are ever changed.
//

import SwiftUI
import UniformTypeIdentifiers

struct NCOAImportView: View {

    @State private var viewModel: NCOAImportViewModel
    @State private var isShowingFileImporter = false

    init() {
        do {
            _viewModel = State(
                wrappedValue: NCOAImportViewModel(importService: try NCOAImportService())
            )
        } catch {
            fatalError("Failed to initialize repositories for NCOAImportView: \(error)")
        }
    }

    var body: some View {
        @Bindable var boundViewModel = viewModel

        Form {
            Section {
                Button("Choose NCOA file", systemImage: "doc.badge.plus") {
                    isShowingFileImporter = true
                }
                .disabled(viewModel.isWorking)

                if viewModel.isWorking {
                    ProgressView()
                }
            } footer: {
                Text("Nothing changes until you tap Apply. A donor is only updated when the address on file matches the old address in the file, ignoring casing, spacing and abbreviations such as Ave and Avenue.")
            }

            if let summary = viewModel.summary {
                NCOAImportSummarySectionView(summary: summary, fileName: viewModel.fileName)

                if let applyResult = viewModel.applyResult {
                    NCOAApplyResultSectionView(result: applyResult)
                }

                if summary.applyableCount > 0 {
                    Section {
                        Button("Apply \(summary.applyableCount) address updates") {
                            Task { await viewModel.apply() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.canApply)
                    }
                }

                ForEach(NCOAImportOutcome.displayOrder) { outcome in
                    NCOAImportOutcomeSectionView(
                        outcome: outcome,
                        items: viewModel.items(for: outcome)
                    )
                }
            }
        }
        .navigationTitle("NCOA Address Import")
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
