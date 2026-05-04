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

    // MARK: - Receipt output mode (per organization)

    private static let receiptOutputModeKey = "receiptOutputMode"
    private static let receiptLetterGreetingKey = "receiptLetterGreeting"
    private static let receiptLetterBodyKey = "receiptLetterBody"

    /// How receipts are rendered for printing. Defaults to the legacy drawn path.
    var receiptOutputMode: ReceiptOutputMode {
        get {
            let raw = userDefaults.string(forKey: prefixedKey(Self.receiptOutputModeKey))
            return ReceiptOutputMode(rawValue: raw ?? "") ?? .drawnProgrammatic
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: prefixedKey(Self.receiptOutputModeKey))
        }
    }

    /// Greeting line template for template-based receipts. Falls back to the
    /// builder default when unset/empty.
    var receiptLetterGreeting: String {
        get {
            let stored = userDefaults.string(forKey: prefixedKey(Self.receiptLetterGreetingKey))
            return (stored?.isEmpty == false) ? stored! : ReceiptFieldValuesBuilder.defaultGreetingTemplate
        }
        set {
            userDefaults.set(newValue, forKey: prefixedKey(Self.receiptLetterGreetingKey))
        }
    }

    /// Multi-paragraph body template for template-based receipts. Falls back to
    /// the builder default when unset/empty.
    var receiptLetterBody: String {
        get {
            let stored = userDefaults.string(forKey: prefixedKey(Self.receiptLetterBodyKey))
            return (stored?.isEmpty == false) ? stored! : ReceiptFieldValuesBuilder.defaultBodyTemplate
        }
        set {
            userDefaults.set(newValue, forKey: prefixedKey(Self.receiptLetterBodyKey))
        }
    }

    /// Combined templates passed to the printing pipeline.
    var receiptLetterTemplates: ReceiptLetterTemplates {
        ReceiptLetterTemplates(greeting: receiptLetterGreeting, body: receiptLetterBody)
    }

    /// Removes overrides so defaults are used again.
    func resetReceiptLetterToDefault() {
        userDefaults.removeObject(forKey: prefixedKey(Self.receiptLetterGreetingKey))
        userDefaults.removeObject(forKey: prefixedKey(Self.receiptLetterBodyKey))
    }
}

