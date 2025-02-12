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

/// A default implementation of the OrganizationProvider.
struct DefaultOrganizationProvider: OrganizationProvider {
    var organizationInfo: OrganizationInfo {
        return OrganizationInfo(
            name: "United Tiberias",
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
}

struct SpecialOrganizationProvider: OrganizationProvider {
    var organizationInfo: OrganizationInfo {
        return OrganizationInfo(
            name: "Something else",
            addressLine1: "PO box 9876",
            city: "Scranton",
            state: "PA",
            zip: "98766",
            ein: "11-3345423",
            website: "www.unitedtiberias.com",
            email: "info@unitedtiberias.com",
            phone: "212-555-1234"
        )
    }
}
