//
//  ContentView.swift
//  ioscodeformac
//
//  Created by Steven Hertz on 2/11/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Main Content Area")
            }
            .navigationTitle("My App")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    VStack(spacing: 12) {
                        Button(action: { print("Add tapped") }) {
                            Image(systemName: "plus.circle.fill")
                        }
                        
                        Button(action: { print("Edit tapped") }) {
                            Image(systemName: "pencil.circle.fill")
                        }
                        
                        Button(action: { print("Share tapped") }) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                        }
                    }
                    .font(.title2)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
