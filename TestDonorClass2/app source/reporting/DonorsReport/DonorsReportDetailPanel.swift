//
//  DonorsReportDetailPanel.swift
//  TestDonorClass2
//

import SwiftUI

/// Right column: full donor detail for the selected result.
struct DonorsReportDetailPanel: View {
    @Bindable var viewModel: DonorsReportViewModel

    var body: some View {
        if let id = viewModel.selectedDonorID,
           let index = viewModel.donors.firstIndex(where: { $0.id == id }) {
            DonorDetailView(donor: $viewModel.donors[index])
        } else {
            ContentUnavailableView(
                "Select a Donor",
                systemImage: "person.crop.circle",
                description: Text("Choose a donor from the list to see their full information.")
            )
        }
    }
}
