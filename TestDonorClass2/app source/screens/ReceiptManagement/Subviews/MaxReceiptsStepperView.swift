//
//  MaxReceiptsStepperView.swift
//  TestDonorClass2
//
//  Compact stepper for overriding "Max receipts per print", co-located
//  with the Print All button so cause and effect sit together.
//

import SwiftUI

struct MaxReceiptsStepperView: View {
    let value: Int
    let onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text("Max per print:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.subheadline)
                .frame(minWidth: 24)
            Stepper(
                "",
                value: Binding(get: { value }, set: { onChange($0) }),
                in: 1...100
            )
            .labelsHidden()
            .fixedSize()
        }
    }
}
