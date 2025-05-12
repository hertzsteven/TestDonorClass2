//
//  DatabaseSelectorView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 5/2/25.
//


import SwiftUI

struct DatabaseSelectorView: View {
    let availableDatabases: [String] = ["donations_uti", "donations_co"]
//    @State private var selectedDatabase: String?
    @State private var initError: Error?
    
    var body: some View {
        Group {
            if ApplicationData.shared.selectedDatabase != nil {
                // User has chosen (or auto-chosen) → hand off to AppRootView
                AppRootView()
//                          .alert("Database Error", error: $initError)
            } else {
                VStack(spacing: 16) {
                    Text("Select an Organization")
                        .font(.headline)
                    
                    List(availableDatabases, id: \.self) { db in
                        Button(db) {
                            do {
//                                try DatabaseManager.shared.setDatabaseURL(db)
                                ApplicationData.shared.setDbName(db.appending(".sqlite"))
                            } catch {
                                initError = error
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                .padding()
                .onAppear {
                    print("in on appear")
                    // Auto-pick if there’s only one
                    if availableDatabases.count == 1 {
                        let theDbName = availableDatabases[0]
                        do {
//                            try DatabaseManager.shared.setDatabaseURL(theDbName)
                            ApplicationData.shared.setDbName(theDbName.appending(".sqlite"))
                        } catch {
                            initError = error
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    DatabaseSelectorView()
}
