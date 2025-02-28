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

class DashboardViewModel {
    // Organize categories by domain
    let categories: [Category]
    let sections: [DashboardSection]
    
    init() {
        // Device Management Categories
        let deviceCategories: [Category] = [
            Category(name: "Devices", 
                    color: .blue, 
                    image: Image(systemName: "ipad.and.iphone"), 
                    count: 5),
            Category(name: "Categories", 
                    color: .green, 
                    image: Image(systemName: "folder.fill"), 
                    count: 12)
        ]
        
        // Application Management Categories
        let appCategories: [Category] = [
            Category(name: "Apps", 
                    color: .red, 
                    image: Image(systemName: "apps.ipad"), 
                    count: 3),
            Category(name: "NavigateToStudentAppProfile", 
                    color: .purple, 
                    image: Image(systemName: "person.3.sequence.fill"), 
                    count: 8)
        ]
        
        // User Management Categories
        let userCategories: [Category] = [
            Category(name: "Classes", 
                    color: .orange, 
                    image: Image(systemName: "person.3.sequence.fill"), 
                    count: 2),
            Category(name: "Students", 
                    color: .yellow, 
                    image: Image(systemName: "person.crop.square"), 
                    count: 6)
        ]
        
        // Combine all categories in order
        self.categories = deviceCategories + appCategories + userCategories
        
        // Define sections based on the combined array
        self.sections = [
            DashboardSection(
                title: "Device Management",
                startIndex: 0,
                count: deviceCategories.count
            ),
            DashboardSection(
                title: "Application Management",
                startIndex: deviceCategories.count,
                count: appCategories.count
            ),
            DashboardSection(
                title: "User Management",
                startIndex: deviceCategories.count + appCategories.count,
                count: userCategories.count
            )
        ]
    }
}
