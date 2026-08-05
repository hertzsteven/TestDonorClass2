//
//  DonorsReportResultsPanel.swift
//  TestDonorClass2
//

import SwiftUI

/// Middle column: selectable list of matching donors.
struct DonorsReportResultsPanel: View {
    @Bindable var viewModel: DonorsReportViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text("Donors (\(viewModel.matchingDonorCount))")
                .font(.headline)
                .padding()

            if viewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMsg = viewModel.errorMessage {
                DonorsReportErrorView(message: errorMsg, viewModel: viewModel)
            } else if viewModel.donors.isEmpty {
                ContentUnavailableView(
                    "No Matching Donors",
                    systemImage: "person.slash",
                    description: Text("No donors match the current filters.")
                )
            } else {
                List {
                    ForEach(viewModel.donors) { donor in
                        if let id = donor.id {
                            Button {
                                viewModel.selectedDonorID = id
                            } label: {
                                DonorReportRowView(donor: donor)
                            }
                            .buttonStyle(.plain)
                            .tag(id)
                            .listRowBackground(
                                id == viewModel.selectedDonorID
                                    ? Color.accentColor.opacity(0.12)
                                    : Color.clear
                            )
                        }
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
    }
}

private struct DonorsReportErrorView: View {
    let message: String
    let viewModel: DonorsReportViewModel

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
                Task { await viewModel.refresh() }
            }
            .buttonStyle(.bordered)
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
