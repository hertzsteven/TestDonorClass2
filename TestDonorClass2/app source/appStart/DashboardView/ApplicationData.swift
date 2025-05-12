//
//  ApplicationData.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 5/2/25.
//

import SwiftUI
import Foundation
// ApplicationData.swift - Singleton class with dbName property
@Observable class ApplicationData: @unchecked Sendable {
    // Static property to hold the single instance
    static let shared = ApplicationData()
       
    // Property to store the database name
    private(set) var selectedDatabase: String?
    
    // Private initializer prevents direct instantiation
    private init() {}
    
    // MODIFY: Change logic to check for substrings case-insensitively
    func getOrgTitle() -> String {
        guard let dbName = selectedDatabase?.lowercased() else {
            return "Unknown" // Handle nil case
        }
        
        if dbName.contains("uti") {
            return "United Tiberias"
        } else if dbName.contains("co") {
            return "Chaye Olam"
        } else {
            return "Unknown" // Default if neither substring is found
        }
    }
    
    /// Returns the SwiftUI Image view for the organization's logo.
    /// Assumes corresponding assets exist in the asset catalog (e.g., "uti_logo", "co_logo", "default_logo").
    /// - Returns: A SwiftUI `Image` view.
    func getOrgLogoImage() -> Image {
        let assetName: String // Variable to hold the determined asset name
        
        // Determine the asset name based on the database
        if let dbName = selectedDatabase?.lowercased() {
            if dbName.contains("uti") {
                assetName = "logo-uti"
            } else if dbName.contains("co") {
                assetName = "logo-co"
            } else {
                assetName = "default_logo" // Default if no specific match
            }
        } else {
            assetName = "default_logo" // Default if database name is not set
        }
        
        // Return the Image initialized with the determined asset name
        return Image(assetName)
    }
    
    // Method to set the dbName
    func setDbName(_ name: String) {
        selectedDatabase = name
    }
}

// Usage example:
// let appData = ApplicationData.shared
// appData.setDbName("myDatabase")
// print(appData.selectedDatabase) // "myDatabase"
// print(appData.getOrgTitle())
// let logoImage = appData.getOrgLogoImage() // Get the Image view
