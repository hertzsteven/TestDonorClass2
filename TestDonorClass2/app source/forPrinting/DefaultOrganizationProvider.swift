//
//  DefaultOrganizationProvider.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/6/25.
//


//
//  DefaultOrganizationProvider.swift
//  UseNSAttribute
//
//  Created by Steven Hertz on 2/6/25.
//

import Foundation

/// A default implementation of the OrganizationProvider that dynamically provides info based on ApplicationData.
struct DefaultOrganizationProvider: OrganizationProvider {
    
    // MODIFY: Implement dynamic organization info based on ApplicationData
    var organizationInfo: OrganizationInfo {
        // Access the selected database name from the singleton
        guard let dbName = ApplicationData.shared.selectedDatabase?.lowercased() else {
            // Return default/unknown info if database name is not set
            return unknownOrganizationInfo
        }

        // Check for substrings to determine the organization
        if dbName.contains("uti") {
            return unitedTiberiasInfo
        } else if dbName.contains("co") {
            return chayeOlamInfo
        } else {
            // Return default/unknown info if no match
            return unknownOrganizationInfo
        }
    }

    // ADD: Private computed properties for specific organization details
    private var unitedTiberiasInfo: OrganizationInfo {
        OrganizationInfo(
            name: "United Tiberias", // Updated name
            addressLine1: "PO box 1234",
            city: "New York",
            state: "New York",
            zip: "11234",
            ein: "11-3345423",
            website: "www.unitedtiberias.com",
            email: "info@unitedtiberias.com",
            phone: "212-555-1234"
        )
    }

    private var chayeOlamInfo: OrganizationInfo {
        OrganizationInfo(
            name: "Chaye Olam", // Updated name
            addressLine1: "PO box 9876",
            city: "Scranton",
            state: "PA",
            zip: "98766",
            ein: "11-9876543", // Assuming a different EIN
            website: "www.chayeolam.org", // Assuming different details
            email: "info@chayeolam.org",
            phone: "570-555-5678"
        )
    }
    
    private var unknownOrganizationInfo: OrganizationInfo {
        OrganizationInfo(
            name: "Unknown Organization",
            addressLine1: "Address Not Available",
            city: "N/A",
            state: "N/A",
            zip: "N/A",
            ein: "N/A",
            website: nil,
            email: nil,
            phone: nil
        )
    }
}
