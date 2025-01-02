//
//  RepositoryError.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 12/25/24.
//
import SwiftUI

enum RepositoryError: LocalizedError {
    case fetchFailed(String)
    case insertFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case readAllFailed(String)

    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let reason): return "Failed to fetch donor: \(reason)"
        case .insertFailed(let reason): return "Failed to insert donor: \(reason)"
        case .updateFailed(let reason): return "Failed to update donor: \(reason)"
        case .deleteFailed(let reason): return "Failed to delete donor: \(reason)"
        case .readAllFailed(let reason): return "Failed to read all donors: \(reason)"
        }
    }
}
