//
//  DashboardViewModel.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/27/25.
//


//
//  DashboardViewModel.swift
//  DashboardTemplate
//
//  Created by Steven Hertz on 2/26/25.
//


import SwiftUI
enum CategoryType: String {
    case donations = "Donations"
    case donorHub = "Donor Hub"
    case campaigns = "Campaigns"
    case incentives = "Incentives"
    case classes = "Classes"
    case students = "Students"
    
    var name: String {
         self.rawValue
    }
}

class DashboardViewModel {
    // Organize categories by domain
    let categories: [Category]
    let sections: [DashboardSection]
    
    init() {
        // Donor Management Categories
        let donorCategories: [Category] = [
            Category(name: CategoryType.donations.name,
                     color: .green,
                     image: Image(systemName: "dollarsign")),
            Category(name: CategoryType.donorHub.name,
                    color: .blue,
                    image: Image(systemName: "person")),
            Category(name: "Reports",
                    color: .blue,
                    image: Image(systemName: "person")),
        ]
        
        // Management Categories
        let managementCategories: [Category] = [
            Category(name: "Campaigns",
                    color: .purple,
                    image: Image(systemName: "megaphone")),
            Category(name: "Incentives",
                    color: .orange,
                    image: Image(systemName: "gift")),
            Category(name: "Receipt Management",
                    color: .red,
                    image: Image(systemName: "printer.fill"))
        ]
        
        // User Management Categories
        let userCategories: [Category] = [
            Category(name: "Donors", 
                    color: .orange, 
                    image: Image(systemName: "person.3.sequence.fill")),
            Category(name: "Students",
                    color: .yellow, 
                    image: Image(systemName: "person.crop.square")) 
        ]
        
        // Combine all categories in order
        self.categories = donorCategories + managementCategories + userCategories
        
        // Define sections based on the combined array
        self.sections = [
            DashboardSection(
                title: "Donor Donation Management",
                startIndex: 0,
                count: donorCategories.count
            ),
            DashboardSection(
                title: "Campaign & Incentives",
                startIndex: donorCategories.count,
                count: managementCategories.count
            ),
            DashboardSection(
                title: "User Management",
                startIndex: donorCategories.count + managementCategories.count,
                count: userCategories.count
            )
        ]
    }
}
