//
//  Dashboard.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/26/25.
//

import SwiftUI

struct DashboardView: View {
    
    // ADD: Organization settings manager
    @State private var organizationManager = OrganizationSettingsManager()
    
    private let viewModel: DashboardViewModel = DashboardViewModel()
    
    @State var path = NavigationPath()
    
    // ADD: Animation states
    @State private var isAppearing = false
    @State private var isHelpHovered = false
    @State private var isSettingsHovered = false
    @State private var gradientStart = UnitPoint(x: 0, y: 0)
    
    @State private var showingSettings = false
    @State private var showingHelp = false
    
    @EnvironmentObject private var donorObject: DonorObjectClass
    @EnvironmentObject private var donationObject: DonationObjectClass
    @EnvironmentObject private var campaignObject: CampaignObjectClass
    @EnvironmentObject private var incentiveObject: DonationIncentiveObjectClass
    @EnvironmentObject private var defaultDonationSettingsViewModel: DefaultDonationSettingsViewModel
    
    // ENHANCE: Animated background
    var backGroundView: some View {
        LinearGradient(
            colors: [Color(.systemGray6), Color(.systemGray5)],
            startPoint: gradientStart,
            endPoint: UnitPoint(x: 1, y: 1)
        )
        .opacity(0.8)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 5.0).repeatForever()) {
                gradientStart = UnitPoint(x: 1, y: 1)
            }
        }
    }
    
    
    var body: some View {
        NavigationStack(path: $path) {
            
            
            ZStack {
                
                backGroundView
                
                
                ScrollView {
                    GridOfCategoriesSubView(
                        categories: viewModel.categories,
                        sections: viewModel.sections
                    )
                    // ADD: Fade in animation
                    .opacity(isAppearing ? 1 : 0)
                    .animation(.easeIn(duration: 0.6), value: isAppearing)
                }
//                .navigationTitle("United Tiberias: Dashboard")
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack {
                            HStack {
                                Text("United Tiberias: Dashboard")
                                    .font(.headline)
                                Image("orhtorahlogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                            }
                            Text("Management System")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationDestination(for: Category.self) { category in
                switch category.name {
                case "Donor Hub":
                    DonorListView(donorObject: donorObject, maintenanceMode: false)
                    //                        .task {
                    //                            await donorObject.loadDonors()
                    //                        }

                case "Donations":
                    BatchDonationView()
                        .environmentObject(donorObject)
                case "Campaigns":
                    CampaignListView(campaignObject: campaignObject)
                case "Incentives":
                    DonationIncentiveListView(incentiveObject: incentiveObject)
                case "Receipt Management":
                    ReceiptManagementView()
                        .environmentObject(donationObject) // Pass any needed objects
                case "Donors":
                    DonorSearchView(donorObject: donorObject)
                        .task {
                            await donorObject.loadDonors()
                        }
                case "Reports": // Add a new category for reports
                    DonationReportView()
                         // Pass necessary environment objects if needed by subviews
                        .environmentObject(donorObject) // If DonorSearchView needs it
//                case "Classes":
//                    DonorMaintenanceView()
////                        .environmentObject(donorObject)
//                        .environmentObject(donationObject)
                default:
                    Text("Detail view for \(category.name)")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // ENHANCE: Interactive help button
                        Button(action: { showingHelp = true }) {
                            Image(systemName: "questionmark.circle")
                                .scaleEffect(isHelpHovered ? 1.1 : 1.0)
                                .foregroundColor(isHelpHovered ? .blue : .primary)
                        }
                        .buttonStyle(.plain)
                        .onHover { hover in
                            withAnimation(.spring()) {
                                isHelpHovered = hover
                            }
                        }
                        
                        // ENHANCE: Interactive settings button
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                                .scaleEffect(isSettingsHovered ? 1.1 : 1.0)
                                .foregroundColor(isSettingsHovered ? .blue : .primary)
                        }
                        .buttonStyle(.plain)
                        .onHover { hover in
                            withAnimation(.spring()) {
                                isSettingsHovered = hover
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(organizationManager: organizationManager)
                    .environmentObject(donorObject)
                    .environmentObject(donationObject)
                    .environmentObject(campaignObject)
                    .environmentObject(incentiveObject)
                    .environmentObject(defaultDonationSettingsViewModel)
            }
            .sheet(isPresented: $showingHelp) {
                HelpCenterView()
            }
        }
        // Trigger initial fade-in animation
        .onAppear {
            withAnimation {
                isAppearing = true
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
