//
//  DonorDateRangeFilterView.swift
//  TestDonorClass2
//

import SwiftUI

/// Reusable date-range filter controls for Added / Updated sections.
struct DonorDateRangeFilterView: View {
    let title: String
    @Binding var filter: DonorDateRangeFilter

    var body: some View {
        Section(title) {
            Picker("Preset", selection: $filter.preset) {
                ForEach(DonorDatePreset.allCases) { preset in
                    Text(preset.rawValue).tag(preset)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: filter.preset) { _, newPreset in
                if newPreset == .custom {
                    let today = Date()
                    if filter.customFrom == nil {
                        filter.customFrom = today
                    }
                    if filter.customTo == nil {
                        filter.customTo = today
                    }
                }
            }

            if filter.preset == .custom {
                DatePicker(
                    "From:",
                    selection: Binding(
                        get: { filter.customFrom ?? Date() },
                        set: { filter.customFrom = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)

                DatePicker(
                    "To:",
                    selection: Binding(
                        get: { filter.customTo ?? Date() },
                        set: { filter.customTo = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
            }
        }
    }
}
