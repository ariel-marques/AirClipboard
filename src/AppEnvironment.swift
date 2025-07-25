//
//  AppEnvironment.swift
//  AirClipboard
//
//  Centralized app environment and state manager using SwiftUI's ObservableObject.
//  Handles theme, language, license, trial logic, and custom feature toggles.
//  Demonstrates best practices for global state, reactivity, and persistence in macOS apps.
//

import SwiftUI

/// Represents the possible license states for the app.
enum LicenseStatus: String {
    case free
    case trial
    case pro_lifetime
}

/// Global environment manager for AirClipboard.
/// Holds app-wide settings such as theme, language, license state, and custom feature flags.
class AppEnvironment: ObservableObject {
    static let shared = AppEnvironment()

    // MARK: - Language

    @Published var selectedLanguage: String

    // MARK: - Shake Gesture

    @AppStorage("enableShakeGesture") var enableShakeGesture: Bool = true
    @AppStorage("shakeModifier") var shakeModifier: String = "shift"

    enum ShakeModifierKey: String, CaseIterable {
        case shift, command, option
    }

    @AppStorage("selectedShakeModifier") var selectedShakeModifier: String = ShakeModifierKey.shift.rawValue

    /// Returns the appropriate modifier flag for the selected shake gesture.
    var currentShakeModifier: NSEvent.ModifierFlags {
        switch ShakeModifierKey(rawValue: selectedShakeModifier) ?? .shift {
        case .shift:   return .shift
        case .command: return .command
        case .option:  return .option
        }
    }

    /// Returns the active locale for localization.
    var locale: Locale {
        switch selectedLanguage {
        case "pt": return Locale(identifier: "pt_BR")
        case "en": return Locale(identifier: "en_US")
        default:   return Locale.current
        }
    }

    /// Updates the app's language and persists it to UserDefaults.
    func updateLanguage(_ newValue: String) {
        selectedLanguage = newValue
        UserDefaults.standard.set(newValue, forKey: "selectedLanguage")
        objectWillChange.send()
    }

    // MARK: - Theme

    @Published var selectedTheme: AppTheme = {
        let rawValue = UserDefaults.standard.string(forKey: "selectedAppTheme") ?? "system"
        return AppTheme(rawValue: rawValue) ?? .system
    }()

    var colorScheme: ColorScheme? {
        selectedTheme.colorScheme
    }

    /// Updates the app's theme and persists it.
    func updateTheme(_ newValue: AppTheme) {
        selectedTheme = newValue
        UserDefaults.standard.set(newValue.rawValue, forKey: "selectedAppTheme")
        objectWillChange.send()
    }

    // MARK: - License

    @Published var licenseStatus: LicenseStatus = {
        if let saved = UserDefaults.standard.string(forKey: "licenseStatus"),
           let status = LicenseStatus(rawValue: saved) {
            return status
        } else {
            return .free
        }
    }()

    /// Updates the license status and persists it.
    func updateLicenseStatus(_ newValue: LicenseStatus) {
        licenseStatus = newValue
        UserDefaults.standard.set(newValue.rawValue, forKey: "licenseStatus")
        objectWillChange.send()
    }

    // MARK: - Trial

    @AppStorage("trialStartDate") private var trialStartDateString: String = ""
    let trialDurationDays: Int = 7

    /// Returns true if trial is currently active.
    var isTrialActive: Bool {
        if licenseStatus == .trial {
            return trialDaysLeft > 0
        }
        return false
    }

    /// Returns the remaining days in the trial period.
    var trialDaysLeft: Int {
        guard let startDate = trialStartDate else { return 0 }
        let elapsed = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        let remaining = trialDurationDays - elapsed
        return max(remaining, 0)
    }

    private var trialStartDate: Date? {
        guard !trialStartDateString.isEmpty else { return nil }
        return ISO8601DateFormatter().date(from: trialStartDateString)
    }

    /// Starts a trial if not already started.
    func startTrialIfNeeded() {
        if trialStartDate == nil {
            trialStartDateString = ISO8601DateFormatter().string(from: Date())
            if licenseStatus == .free {
                updateLicenseStatus(.trial)
            }
        }
    }

    /// Initialization (intelligent language logic)
    private init() {
        let saved = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "system"
        if saved == "system" {
            let region = Locale.current.identifier
            if region.contains("pt") {
                selectedLanguage = "pt"
            } else {
                selectedLanguage = "en"
            }
        } else {
            selectedLanguage = saved
        }
        // No forced license logic in init!
    }
}
