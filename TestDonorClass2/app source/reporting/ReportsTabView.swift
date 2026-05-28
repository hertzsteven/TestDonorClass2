//
//  ReportsTabView.swift
//  TestDonorClass2
//

import SwiftUI

/// Top-level reports container. Hosts a segmented picker that lets the
/// user switch between the per-donation report and the aggregated
/// top-donors report without changing either underlying screen.
struct ReportsTabView: View {
    @State private var selectedMode: ReportMode = .donations

    var body: some View {
        VStack(spacing: 0) {
            Picker("Report", selection: $selectedMode) {
                ForEach(ReportMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            switch selectedMode {
            case .donations:
                DonationReportView()
            case .topDonors:
                TopDonorsReportView()
            }
        }
    }

    enum ReportMode: String, CaseIterable, Identifiable {
        case donations = "Donations"
        case topDonors = "Top Donors"

        var id: String { rawValue }
    }
}
