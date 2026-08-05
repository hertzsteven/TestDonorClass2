//
//  DonorsReportView.swift
//  TestDonorClass2
//

import SwiftUI

/// Donor-centric report: filter the donor table by attributes, browse matches
/// with addresses visible, and open full donor detail in a third pane.
struct DonorsReportView: View {

    @State private var viewModel: DonorsReportViewModel

    init() {
        do {
            let donorRepo = try DonorRepository()
            _viewModel = State(
                wrappedValue: DonorsReportViewModel(donorRepository: donorRepo)
            )
        } catch {
            fatalError("Failed to initialize repositories for DonorsReportView: \(error)")
        }
    }

    var body: some View {
        @Bindable var vm = viewModel

        HStack(spacing: 0) {
            DonorsReportFilterPanel(viewModel: vm)
                .frame(width: 300)

            Divider()

            DonorsReportResultsPanel(viewModel: vm)
                .frame(width: 380)

            Divider()

            DonorsReportDetailPanel(viewModel: vm)
                .frame(maxWidth: .infinity)
        }
        .task {
            if viewModel.donors.isEmpty && viewModel.errorMessage == nil {
                await viewModel.loadInitialData()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Refresh", systemImage: "arrow.clockwise") {
                    Task { await viewModel.refresh() }
                }
                .disabled(viewModel.isLoading)
            }
        }
        .navigationTitle("Donors")
    }
}
