//
//  DonorSelectionView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/2/25.
//

import SwiftUI
// Example view to show loading states
struct DonorSelectionView: View {
    @EnvironmentObject var donorObject: DonorObjectClass
    
    var body: some View {
        Group {
            
            switch donorObject.loadingState {
                
            case .notLoaded:
                ProgressView("Not yet loaded")
                
            case .loading:
                ProgressView("Loading donors...")
                    .progressViewStyle(CircularProgressViewStyle())
                
            case .loaded:
                if donorObject.donors.isEmpty {
                    Text("No donors available")
                } else {
                    List(donorObject.donors) { donor in
                        Text("\(donor.firstName) \(donor.lastName)")
                    }
                }
                
            case .error(let message):
                VStack {
                    Text("Error loading donors")
                        .foregroundColor(.red)
                    Text(message)
                        .font(.caption)
                    Button("Retry") {
                        Task {
                            try? await donorObject.loadDonors()
                        }
                    }
                }
            }
        }
        .navigationTitle("Donors")
    }
}
