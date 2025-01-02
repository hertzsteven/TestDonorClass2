//
//  LoadingState.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/2/25.
//


import SwiftUI

// Define loading states
enum LoadingState: Equatable {
    case notLoaded
    case loading
    case loaded
    case error(String)
    
        // Custom Equatable implementation to handle the associated value
        static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
            switch (lhs, rhs) {
            case (.notLoaded, .notLoaded):
                return true
            case (.loading, .loading):
                return true
            case (.loaded, .loaded):
                return true
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
}