//
//  DonorFieldPresence.swift
//  TestDonorClass2
//

import Foundation

/// Whether a donor field must be present, missing, or either.
enum DonorFieldPresence: String, CaseIterable, Identifiable {
    case any = "Any"
    case present = "Has"
    case missing = "Missing"

    var id: String { rawValue }
}
