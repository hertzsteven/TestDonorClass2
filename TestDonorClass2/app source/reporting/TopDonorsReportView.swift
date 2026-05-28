//
//  TopDonorsReportView.swift
//  TestDonorClass2
//

import SwiftUI

/// Report screen showing donors aggregated by their giving — the
/// "important / big donors" view. Filters let the user surface repeat
/// donors and donors above a cumulative-giving threshold.
struct TopDonorsReportView: View {

    @State private var viewModel: TopDonorsReportViewModel

    init() {
        do {
            let donationRepo = try DonationRepository()
            let donorRepo = try DonorRepository()
            let campaignRepo = try CampaignRepository()
            _viewModel = State(
                wrappedValue: TopDonorsReportViewModel(
                    donationRepository: donationRepo,
                    donorRepository: donorRepo,
                    campaignRepository: campaignRepo
                )
            )
        } catch {
            fatalError("Failed to initialize repositories for TopDonorsReportView: \(error)")
        }
    }

    var body: some View {
        @Bindable var vm = viewModel

        HStack(spacing: 0) {
            TopDonorsFilterPanel(viewModel: vm)
                .frame(width: 400)

            Divider()

            TopDonorsResultsPanel(viewModel: vm)
        }
        .task {
            if viewModel.summaries.isEmpty {
                await viewModel.loadInitialData()
            }
        }
        .navigationTitle("Top Donors")
    }
}

// MARK: - Filter Panel

private struct TopDonorsFilterPanel: View {
    @Bindable var viewModel: TopDonorsReportViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                TopDonorsFilterSection(viewModel: viewModel)
            }
            Divider()
            TopDonorsSummaryCard(viewModel: viewModel)
        }
    }
}

private struct TopDonorsFilterSection: View {
    @Bindable var viewModel: TopDonorsReportViewModel

    var body: some View {
        Section("Filters") {
            TopDonorsMinTotalField(viewModel: viewModel)
            TopDonorsMinCountStepper(viewModel: viewModel)
            TopDonorsCampaignPicker(viewModel: viewModel)
            TopDonorsDateRangeField(viewModel: viewModel)
            TopDonorsSortPicker(viewModel: viewModel)

            Button("Reset Filters", systemImage: "arrow.counterclockwise") {
                viewModel.resetFilters()
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct TopDonorsMinTotalField: View {
    @Bindable var viewModel: TopDonorsReportViewModel
    @State private var text: String = ""

    var body: some View {
        HStack {
            Text("Minimum total:")
            Spacer()
            TextField("Any", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
                .onChange(of: text) { _, newValue in
                    if newValue.isEmpty {
                        viewModel.criteria.minTotalAmount = nil
                    } else if let value = Double(newValue) {
                        viewModel.criteria.minTotalAmount = value
                    }
                }
                .onAppear {
                    if let amount = viewModel.criteria.minTotalAmount {
                        text = String(amount)
                    }
                }
        }
    }
}

private struct TopDonorsMinCountStepper: View {
    @Bindable var viewModel: TopDonorsReportViewModel

    var body: some View {
        Stepper(
            value: $viewModel.criteria.minDonationCount,
            in: 1...50
        ) {
            HStack {
                Text("Minimum donations:")
                Spacer()
                Text("\(viewModel.criteria.minDonationCount)")
                    .bold()
            }
        }
    }
}

private struct TopDonorsCampaignPicker: View {
    @Bindable var viewModel: TopDonorsReportViewModel

    var body: some View {
        Picker("Campaign", selection: $viewModel.criteria.campaignId) {
            Text("All Campaigns").tag(Int?.none)
            ForEach(viewModel.availableCampaigns) { campaign in
                Text(campaign.name).tag(campaign.id as Int?)
            }
        }
        .pickerStyle(.menu)
    }
}

private struct TopDonorsDateRangeField: View {
    @Bindable var viewModel: TopDonorsReportViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Custom date range", isOn: $viewModel.criteria.useCustomDateRange)
                .onChange(of: viewModel.criteria.useCustomDateRange) { _, isEnabled in
                    if isEnabled {
                        let today = Date()
                        if viewModel.criteria.fromDate == nil {
                            viewModel.criteria.fromDate = today
                        }
                        if viewModel.criteria.toDate == nil {
                            viewModel.criteria.toDate = today
                        }
                    } else {
                        viewModel.criteria.fromDate = nil
                        viewModel.criteria.toDate = nil
                    }
                }

            Text("Only count donations within these dates.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.criteria.useCustomDateRange {
                DatePicker(
                    "From:",
                    selection: Binding(
                        get: { viewModel.criteria.fromDate ?? Date() },
                        set: { viewModel.criteria.fromDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)

                DatePicker(
                    "To:",
                    selection: Binding(
                        get: { viewModel.criteria.toDate ?? Date() },
                        set: { viewModel.criteria.toDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
            }
        }
    }
}

private struct TopDonorsSortPicker: View {
    @Bindable var viewModel: TopDonorsReportViewModel

    var body: some View {
        Picker("Sort by", selection: $viewModel.criteria.sortOption) {
            ForEach(TopDonorSortOption.allCases) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.menu)
    }
}

// MARK: - Summary Card

private struct TopDonorsSummaryCard: View {
    let viewModel: TopDonorsReportViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text("SUMMARY")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top)

            Grid(alignment: .leading, horizontalSpacing: 20) {
                GridRow {
                    Text("Matching Donors:")
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.matchingDonorCount)")
                        .bold()
                }
                GridRow {
                    Text("Combined Total:")
                        .foregroundStyle(.secondary)
                    Text(viewModel.matchingTotalAmount, format: .currency(code: "USD"))
                        .bold()
                }
                GridRow {
                    Text("Donation Count:")
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.matchingDonationCount)")
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
        .background(Color(.systemBackground))
    }
}

// MARK: - Results Panel

private struct TopDonorsResultsPanel: View {
    let viewModel: TopDonorsReportViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text("Top Donors (\(viewModel.matchingDonorCount))")
                .font(.headline)
                .padding()

            if viewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMsg = viewModel.errorMessage {
                TopDonorsErrorView(message: errorMsg, viewModel: viewModel)
            } else if viewModel.summaries.isEmpty {
                Text("No donors match the current filters.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TopDonorsList(viewModel: viewModel)
            }
        }
    }
}

private struct TopDonorsList: View {
    let viewModel: TopDonorsReportViewModel

    var body: some View {
        List {
            ForEach(viewModel.summaries.enumerated(), id: \.element.id) { index, summary in
                TopDonorSummaryRow(summary: summary, rank: index + 1)
            }
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.isRecomputing {
                ProgressView()
                    .padding()
                    .background(.thinMaterial, in: .rect(cornerRadius: 8))
            }
        }
    }
}

private struct TopDonorsErrorView: View {
    let message: String
    let viewModel: TopDonorsReportViewModel

    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text("Error Loading Report")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry", systemImage: "arrow.clockwise") {
                Task { await viewModel.loadInitialData() }
            }
            .buttonStyle(.bordered)
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
