//
//  PreferencesView.swift
//  AirClipboard
//
//  Modular SwiftUI implementation for the app's preferences/settings window.
//  Demonstrates sidebar navigation, dynamic content loading, localization, and seamless integration with app state.
//
import SwiftUI

/// Represents each section in the Preferences sidebar.
enum PreferencesSection: String, CaseIterable, Identifiable {
    case general, history, language, permissions, /* advanced, */ license, about

    var id: String { self.rawValue }

    /// Returns the appropriate SF Symbol for the section.
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .history: return "clock.arrow.circlepath"
        case .language: return "globe"
        case .permissions: return "lock.shield"
        case .license: return "key"
        case .about: return "laptopcomputer"
        }
    }

    /// Returns the localized title for the section.
    var localizedTitle: LocalizedStringKey {
        switch self {
        case .general: return "section_general"
        case .history: return "section_history"
        case .language: return "section_language"
        case .permissions: return "section_permissions"
        case .license: return "section_license"
        case .about: return "section_about"
        }
    }
}

/// Main SwiftUI view for app preferences: sidebar + dynamic content area.
struct PreferencesView: View {
    @State private var selectedSection: PreferencesSection = .general
    @ObservedObject private var environment = AppEnvironment.shared

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar with navigation for each preferences section
            VStack(alignment: .leading, spacing: 0) {
                List(PreferencesSection.allCases, id: \.self, selection: $selectedSection) { section in
                    Label(section.localizedTitle, systemImage: section.icon)
                        .padding(.vertical, 6)
                        .tag(section)
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 180, idealWidth: 200, maxWidth: 220)
            .onReceive(NotificationCenter.default.publisher(for: .selectPreferencesSection)) { notification in
                if let section = notification.object as? PreferencesSection {
                    selectedSection = section
                }
            }
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Dynamic content area for the selected section
            VStack(alignment: .leading) {
                contentForSelectedSection(selectedSection)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
        }
        .environment(\.locale, environment.locale)
        .frame(minWidth: 620, minHeight: 500)
    }

    /// Returns the content view for the selected section.
    @ViewBuilder
    private func contentForSelectedSection(_ section: PreferencesSection) -> some View {
        switch section {
        case .general:
            GeneralPreferencesView()
        case .history:
            HistoryPreferencesView()
        case .language:
            LanguagePreferencesView()
        case .permissions:
            PermissionsPreferencesView()
        case .license:
            LicensePreferencesView()
        case .about:
            AboutPreferencesView()
        }
    }
}

#Preview {
    PreferencesView()
}
