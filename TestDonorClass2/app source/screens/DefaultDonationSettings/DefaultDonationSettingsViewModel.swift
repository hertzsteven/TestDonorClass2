import Foundation
import SwiftUI

enum SettingsError: LocalizedError {
    case decodingFailed
    case encodingFailed
    case savingFailed
    
    var errorDescription: String? {
        switch self {
        case .decodingFailed:
            return "Failed to load settings"
        case .encodingFailed:
            return "Failed to prepare settings for saving"
        case .savingFailed:
            return "Failed to save settings"
        }
    }
}

class DefaultDonationSettingsViewModel: ObservableObject {
    @Published var settings: DefaultDonationSettings
    @Published var error: SettingsError?
    
    private let settingsKey = "defaultDonationSettings"
    
    init() {
        // Load settings from UserDefaults or create new settings
        if let data = UserDefaults.standard.data(forKey: settingsKey) {
            do {
                self.settings = try JSONDecoder().decode(DefaultDonationSettings.self, from: data)
            } catch {
                self.error = .decodingFailed
                self.settings = DefaultDonationSettings()
            }
        } else {
            self.settings = DefaultDonationSettings()
        }
    }
    
    func saveSettings() -> Bool {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: settingsKey)
            return true
        } catch {
            self.error = .encodingFailed
            return false
        }
    }
    
    func clearError() {
        error = nil
    }
}
