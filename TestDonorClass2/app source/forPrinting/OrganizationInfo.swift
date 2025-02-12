//
//  OrganizationInfo.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/6/25.
//



import Foundation

/// Model representing the organization's details.
struct OrganizationInfo {
    let name: String
    let addressLine1: String
    let city: String
    let state: String
    let zip: String
    let ein: String
    let website: String?
    let email: String?
    let phone: String?

    /// A computed property to format the organization details.
    var formattedInfo: String {
        """
        \(name)
        \(addressLine1)
        \(city), \(state) \(zip)
        """
    }
}
