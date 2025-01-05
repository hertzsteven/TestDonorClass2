import Foundation
import SwiftUI

class DefaultDonationSettingsViewModel: ObservableObject {
    @Published var settings: DefaultDonationSettings
    
    init() {
        // Load settings from UserDefaults or create new settings
        if let data = UserDefaults.standard.data(forKey: "defaultDonationSettings"),
           let loadedSettings = try? JSONDecoder().decode(DefaultDonationSettings.self, from: data) {
            self.settings = loadedSettings
        } else {
            self.settings = DefaultDonationSettings()
        }
    }
    
    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "defaultDonationSettings")
            UserDefaults.standard.synchronize()
        }
    }
}

// End of file. No additional code.
