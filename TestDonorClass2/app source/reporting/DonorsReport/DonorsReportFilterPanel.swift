//
//  DonorsReportFilterPanel.swift
//  TestDonorClass2
//

import SwiftUI

/// Left column: filter form plus matching-donor summary.
struct DonorsReportFilterPanel: View {
    @Bindable var viewModel: DonorsReportViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                DonorDateRangeFilterView(
                    title: "Date Added",
                    filter: $viewModel.criteria.addedRange
                )

                DonorDateRangeFilterView(
                    title: "Date Updated",
                    filter: $viewModel.criteria.updatedRange
                )

                Section("Contact Fields") {
                    Picker("Email", selection: $viewModel.criteria.emailPresence) {
                        ForEach(DonorFieldPresence.allCases) { presence in
                            Text(emailLabel(for: presence)).tag(presence)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Address", selection: $viewModel.criteria.addressPresence) {
                        ForEach(DonorFieldPresence.allCases) { presence in
                            Text(addressLabel(for: presence)).tag(presence)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Sort") {
                    Picker("Sort by", selection: $viewModel.criteria.sortOption) {
                        ForEach(DonorReportSortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)

                    Button("Reset Filters", systemImage: "arrow.counterclockwise") {
                        viewModel.resetFilters()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Divider()

            DonorsReportSummaryCard(viewModel: viewModel)
        }
    }

    private func emailLabel(for presence: DonorFieldPresence) -> String {
        switch presence {
        case .any: return "Any"
        case .present: return "Has email"
        case .missing: return "Missing email"
        }
    }

    private func addressLabel(for presence: DonorFieldPresence) -> String {
        switch presence {
        case .any: return "Any"
        case .present: return "Has address"
        case .missing: return "Missing address"
        }
    }
}

private struct DonorsReportSummaryCard: View {
    let viewModel: DonorsReportViewModel

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
                    Text("With Email:")
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.matchingWithEmailCount)")
                }
                GridRow {
                    Text("With Address:")
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.matchingWithAddressCount)")
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
        .background(.background)
    }
}
