//
//  DonorInstructionsView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/24/25.
//

import SwiftUI

struct ExpandableInstructionRow: View {
    let iconName: String
    let title: String
    let description: String
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: iconName)
                        .foregroundStyle(.blue)
                        .frame(width: 24, height: 24)
                    
                    Text(title)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 36)
                    .padding(.top, 2)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DonorInstructionsView: View {
    var body: some View {

            VStack {
                Text("Donors")
                    .font(.largeTitle)
                    .foregroundColor(.black)
                    .padding(.bottom, 16)
                GroupBox {
                    VStack {
//                    Label("Donor Management Guide", systemImage: "person.text.rectangle")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity, alignment: .center)
//                        .padding(.bottom, 8)
                    
                    // Mode Selection
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Choose Mode")
//                            .font(.headline)
//                        
//                        ExpandableInstructionRow(
//                            iconName: "dollarsign.circle",
//                            title: "Donation Mode",
//                            description: "Enter a new donation for the selected donor. Record payment amounts, methods, and generate receipts."
//                        )
//                        
//                        ExpandableInstructionRow(
//                            iconName: "info.circle",
//                            title: "Information Mode",
//                            description: "View and update donor details including contact information, history, and preferences."
//                        )
//                    }
                    
//                    Divider()
//                        .padding(.vertical, 8)
//                    
                    // Search Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Find a Donor")
                            .font(.headline)
                        
                        ExpandableInstructionRow(
                            iconName: "magnifyingglass",
                            title: "Search by name/company",
                            description: "Enter a name or company in the search bar to find matching donors. Results will update as you type."
                        )
                        
                        ExpandableInstructionRow(
                            iconName: "number",
                            title: "Enter donor ID",
                            description: "Type a donor ID or use the barcode scanner (available in ID search mode) to quickly locate a specific donor."
                        )
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Additional Options
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Options")
                            .font(.headline)
                        
//                        ExpandableInstructionRow(
//                            iconName: "gear",
//                            title: "Default Donation Settings",
//                            description: "Configure default values for new donations such as suggested amounts, payment methods, and receipt templates. Only available in Donation Mode."
//                        )
                        
                        ExpandableInstructionRow(
                            iconName: "plus",
                            title: "Add New Donor",
                            description: "Create a new donor record with contact information and preferences. Only available in Information Mode."
                        )
                    }
                }
                .padding()
            }
//                GroupBox {
//                    VStack {
//                    Label("Donor Management Guide", systemImage: "person.text.rectangle")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity, alignment: .center)
//                        .padding(.bottom, 8)
//                    
//                    // Mode Selection
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Choose Mode")
//                            .font(.headline)
//                        
//                        ExpandableInstructionRow(
//                            iconName: "dollarsign.circle",
//                            title: "Donation Mode",
//                            description: "Enter a new donation for the selected donor. Record payment amounts, methods, and generate receipts."
//                        )
//                        
//                        ExpandableInstructionRow(
//                            iconName: "info.circle",
//                            title: "Information Mode",
//                            description: "View and update donor details including contact information, history, and preferences."
//                        )
//                    }
//                    
//                    Divider()
//                        .padding(.vertical, 8)
//                    
//                    // Search Instructions
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Find a Donor")
//                            .font(.headline)
//                        
//                        ExpandableInstructionRow(
//                            iconName: "magnifyingglass",
//                            title: "Search by name/company",
//                            description: "Enter a name or company in the search bar to find matching donors. Results will update as you type."
//                        )
//                        
//                        ExpandableInstructionRow(
//                            iconName: "number",
//                            title: "Enter donor ID",
//                            description: "Type a donor ID or use the barcode scanner (available in ID search mode) to quickly locate a specific donor."
//                        )
//                    }
//                    
//                    Divider()
//                        .padding(.vertical, 8)
//                    
//                    // Additional Options
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Additional Options")
//                            .font(.headline)
//                        
//                        ExpandableInstructionRow(
//                            iconName: "gear",
//                            title: "Default Donation Settings",
//                            description: "Configure default values for new donations such as suggested amounts, payment methods, and receipt templates. Only available in Donation Mode."
//                        )
//                        
//                        ExpandableInstructionRow(
//                            iconName: "plus",
//                            title: "Add New Donor",
//                            description: "Create a new donor record with contact information and preferences. Only available in Information Mode."
//                        )
//                    }
//                }
//                .padding()
//            }
                Spacer()
        .backgroundStyle(.thinMaterial)
        .padding()
            }
    }
}
