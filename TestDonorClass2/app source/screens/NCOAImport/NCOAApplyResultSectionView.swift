//
//  NCOAApplyResultSectionView.swift
//  TestDonorClass2
//

import SwiftUI

/// What the last apply actually wrote.
struct NCOAApplyResultSectionView: View {
    let result: NCOAApplyResult

    var body: some View {
        Section("Last apply") {
            LabeledContent("Addresses updated") {
                Text(result.updatedCount, format: .number)
                    .bold()
            }

            if result.revalidationFailureCount > 0 {
                LabeledContent("Skipped at write time") {
                    Text(result.revalidationFailureCount, format: .number)
                        .bold()
                        .foregroundStyle(Color.orange)
                }
            }
        }
    }
}
