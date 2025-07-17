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

/// A default implementation of the OrganizationProvider that dynamically provides info from the OrganizationSettingsManager.
struct DefaultOrganizationProvider: OrganizationProvider {
    
    /// Create an instance of the settings manager to access saved organization data.
    private let settingsManager = OrganizationSettingsManager()
    
    /// The `organizationInfo` now comes directly from the settings manager,
    /// which loads the correct data from UserDefaults based on the selected database.
    /// This ensures that the receipts use the user-saved settings.
    var organizationInfo: OrganizationInfo {
        return settingsManager.organizationInfo
    }
}