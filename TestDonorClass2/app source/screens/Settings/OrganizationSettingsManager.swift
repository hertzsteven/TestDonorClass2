import Foundation

@Observable
class OrganizationSettingsManager {
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    
    private func getDatabasePrefix() -> String {
        guard let selectedDatabase = ApplicationData.shared.selectedDatabase else {
            print("No selectedDatabase found, using default prefix")
            return "default"
        }
        
        // Remove file extension
        let prefix = (selectedDatabase as NSString).deletingPathExtension
        print("Database prefix: '\(prefix)' (from selectedDatabase: '\(selectedDatabase)')")
        return prefix
    }
    
    private func prefixedKey(_ key: String) -> String {
        let prefix = getDatabasePrefix()
        let prefixedKey = "\(prefix)_\(key)"
        print("Created prefixed key: '\(prefixedKey)'")
        return prefixedKey
    }
    
    var organizationInfo: OrganizationInfo {
        get {
            print("Loading organization info with database prefix...")
            return OrganizationInfo(
                name: userDefaults.string(forKey: prefixedKey("organizationName")) ?? "",
                addressLine1: userDefaults.string(forKey: prefixedKey("addressLine1")) ?? "",
                city: userDefaults.string(forKey: prefixedKey("city")) ?? "",
                state: userDefaults.string(forKey: prefixedKey("state")) ?? "",
                zip: userDefaults.string(forKey: prefixedKey("zip")) ?? "",
                ein: userDefaults.string(forKey: prefixedKey("ein")) ?? "",
                website: userDefaults.string(forKey: prefixedKey("website")),
                email: userDefaults.string(forKey: prefixedKey("organizationEmail")),
                phone: userDefaults.string(forKey: prefixedKey("phone"))
            )
        }
        set {
            print("Saving organization info with database prefix...")
            userDefaults.set(newValue.name, forKey: prefixedKey("organizationName"))
            userDefaults.set(newValue.addressLine1, forKey: prefixedKey("addressLine1"))
            userDefaults.set(newValue.city, forKey: prefixedKey("city"))
            userDefaults.set(newValue.state, forKey: prefixedKey("state"))
            userDefaults.set(newValue.zip, forKey: prefixedKey("zip"))
            userDefaults.set(newValue.ein, forKey: prefixedKey("ein"))
            userDefaults.set(newValue.website, forKey: prefixedKey("website"))
            userDefaults.set(newValue.email, forKey: prefixedKey("organizationEmail"))
            userDefaults.set(newValue.phone, forKey: prefixedKey("phone"))
            print("Organization info saved successfully with prefix")
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
