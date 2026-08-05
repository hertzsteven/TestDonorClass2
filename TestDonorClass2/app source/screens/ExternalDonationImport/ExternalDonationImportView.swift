//
//  ExternalDonationImportView.swift
//  TestDonorClass2
//
//  Import external donations (OJC, Donors Fund, Website, Zelle). Work reachable
//  rows first, decide and apply one at a time, or batch-apply a finished group.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExternalDonationImportView: View {

    @State private var viewModel: ExternalDonationImportViewModel
    @State private var isShowingFileImporter = false
    @State private var itemBeingDecided: ExternalDonationItem?
    @State private var donorRepository: (any DonorSpecificRepositoryProtocol)?

    init() {
        do {
            let importService = try ExternalDonationImportService()
            let campaignRepository = try CampaignRepository()
            _viewModel = State(
                wrappedValue: ExternalDonationImportViewModel(
                    importService: importService,
                    campaignRepository: campaignRepository
                )
            )
            _donorRepository = State(initialValue: try DonorRepository())
        } catch {
            fatalError("Failed to initialize repositories for ExternalDonationImportView: \(error)")
        }
    }

    var body: some View {
        @Bindable var boundViewModel = viewModel

        Form {
            Section {
                Button("Choose donations file", systemImage: "doc.badge.plus") {
                    isShowingFileImporter = true
                }
                .disabled(viewModel.isWorking)

                if viewModel.isWorking {
                    ProgressView()
                }
            } footer: {
                Text("Start with rows that have an email or postal address. Tap a row to decide and apply that one donation, or finish decisions for the group and apply them together.")
            }

            if !viewModel.items.isEmpty {
                Section("Which rows to work on") {
                    Picker("Contact group", selection: $boundViewModel.contactFilter) {
                        ForEach(ExternalDonationContactFilter.allCases) { filter in
                            Text(title(for: filter)).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)

                    LabeledContent("Has email or address") {
                        Text(viewModel.withContactCount, format: .number)
                    }
                    LabeledContent("No email or address") {
                        Text(viewModel.withoutContactCount, format: .number)
                    }
                }

                Section("Campaign (optional)") {
                    Picker("Campaign", selection: $boundViewModel.selectedCampaignId) {
                        Text("None").tag(Int?.none)
                        ForEach(viewModel.campaigns) { campaign in
                            Text(campaign.name).tag(Optional(campaign.id))
                        }
                    }
                }

                ExternalDonationSummarySectionView(
                    summary: viewModel.filteredSummary,
                    fileName: viewModel.fileName,
                    groupTitle: viewModel.contactFilter.title
                )

                if let applyResult = viewModel.applyResult {
                    ExternalDonationApplyResultSectionView(result: applyResult)
                }

                let summary = viewModel.filteredSummary
                if summary.undecidedCount > 0 {
                    Section {
                        Text("\(summary.undecidedCount) rows in this group still need a decision before you can batch-apply. You can still open a row and use Apply now for that one donation.")
                            .foregroundStyle(Color.orange)
                    }
                }

                if summary.applyableCount > 0 {
                    Section {
                        Button("Apply \(summary.applyableCount) in this group") {
                            Task { await viewModel.applyFiltered() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.canApplyFiltered)
                    } footer: {
                        Text("Writes only ready rows in “\(viewModel.contactFilter.title)”. The other group is left alone.")
                    }
                }

                ForEach(ExternalDonationOutcome.displayOrder) { outcome in
                    ExternalDonationOutcomeSectionView(
                        outcome: outcome,
                        items: viewModel.items(for: outcome)
                    ) { item in
                        itemBeingDecided = item
                    }
                }
            }
        }
        .navigationTitle("External Donations")
        .task {
            await viewModel.loadCampaigns()
        }
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
        .sheet(item: $itemBeingDecided) { item in
            if let donorRepository {
                ExternalDonationDecisionView(
                    item: item,
                    donorRepository: donorRepository,
                    onDecide: { decision in
                        viewModel.decide(decision, for: item.id)
                    },
                    onDecideAndApply: { decision in
                        Task {
                            await viewModel.decideAndApply(decision, for: item.id)
                        }
                    }
                )
            }
        }
        .alert("Import failed", isPresented: $boundViewModel.isShowingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func title(for filter: ExternalDonationContactFilter) -> String {
        switch filter {
        case .withContact:
            "With contact (\(viewModel.withContactCount))"
        case .withoutContact:
            "No contact (\(viewModel.withoutContactCount))"
        }
    }
}
