import Foundation

@Observable
class OrganizationSettingsManager {
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    
    var organizationInfo: OrganizationInfo {
        get {
            OrganizationInfo(
                name: userDefaults.string(forKey: "organizationName") ?? "",
                addressLine1: userDefaults.string(forKey: "addressLine1") ?? "",
                city: userDefaults.string(forKey: "city") ?? "",
                state: userDefaults.string(forKey: "state") ?? "",
                zip: userDefaults.string(forKey: "zip") ?? "",
                ein: userDefaults.string(forKey: "ein") ?? "",
                website: userDefaults.string(forKey: "website"),
                email: userDefaults.string(forKey: "organizationEmail"),
                phone: userDefaults.string(forKey: "phone")
            )
        }
        set {
            userDefaults.set(newValue.name, forKey: "organizationName")
            userDefaults.set(newValue.addressLine1, forKey: "addressLine1")
            userDefaults.set(newValue.city, forKey: "city")
            userDefaults.set(newValue.state, forKey: "state")
            userDefaults.set(newValue.zip, forKey: "zip")
            userDefaults.set(newValue.ein, forKey: "ein")
            userDefaults.set(newValue.website, forKey: "website")
            userDefaults.set(newValue.email, forKey: "organizationEmail")
            userDefaults.set(newValue.phone, forKey: "phone")
        }
    }
    
    // MARK: - Methods
    func saveOrganizationInfo(_ info: OrganizationInfo) {
        self.organizationInfo = info
    }
    
    func loadDefaultOrganization() {
        let defaultProvider = DefaultOrganizationProvider()
        self.organizationInfo = defaultProvider.organizationInfo
    }
}