//
//  Dashboard.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/26/25.
//

import SwiftUI


struct DashboardView: View {
    
    private let viewModel: DashboardViewModel = DashboardViewModel()
    
    @State var path = NavigationPath()
    
    @State private var showingSettings = false
    @State private var showingHelp = false
    
    var backGroundView: some View {
        Color(.systemGray6)
            .opacity(0.8)
            .ignoresSafeArea()
    }
    
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                
                backGroundView
                
                GridOfCategoriesSubView(
                    categories: viewModel.categories,
                    sections: viewModel.sections
                )
                .navigationTitle("United Tiberias: Dashboard")
            }
            .navigationDestination(for: Category.self) { category in
                Text("Detail view for \(category.name)")
            }
            .toolbar(content: doToolbarTraing)
            .sheet(isPresented: $showingSettings) {
                Text("Settings View")
                    .navigationTitle("Settings")
            }
            .sheet(isPresented: $showingHelp) {
                Text("Help View")
                    .navigationTitle("Help")
            }
        }
    }
}

//  MARK: -  funcs that build tool bar
extension DashboardView {
    @ToolbarContentBuilder
    func doToolbarTraing() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                Button(action: { showingHelp = true }) {
                    Image(systemName: "questionmark.circle")
                }
                
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                }
            }
        }
    }
}


#Preview {
    DashboardView()
}
