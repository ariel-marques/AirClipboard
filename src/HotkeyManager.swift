//
//  HotkeyManager.swift
//  AirClipboard (Public Curated Example)
//
//  Handles global keyboard shortcut registration for opening AirClipboard.
//  Supports user-customizable shortcuts, with parsing of macOS-style key combinations.
//  Demonstrates clean Swift and system integration patterns.
//
import Foundation
import HotKey
import AppKit

/// Singleton responsible for managing the global keyboard shortcut (hotkey).
class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var hotKey: HotKey?

    /// Registers the global hotkey, using a user-defined shortcut or a default.
    func register() {
        let shortcutString = UserDefaults.standard.string(forKey: "shortcutKey") ?? "⌃⌘V"
        updateShortcut(shortcutString)
    }

    /// Updates the current global hotkey based on the provided string.
    /// Expects macOS-style symbols (e.g. ⌃⌘V).
    func updateShortcut(_ shortcut: String) {
        // Cancels previous hotkey (if any).
        hotKey = nil

        // Parses the shortcut string to extract key and modifier flags.
        guard let parsed = parseShortcut(shortcut) else {
            return
        }

        hotKey = HotKey(key: parsed.key, modifiers: parsed.modifiers)
        hotKey?.keyDownHandler = {
            // This handler toggles the main AirClipboard window.
            WindowManager.shared.toggleMainWindow()
        }
    }

    /// Parses a macOS-style shortcut string (e.g., "⌃⌘V") to Key and ModifierFlags.
    private func parseShortcut(_ shortcut: String) -> (key: Key, modifiers: NSEvent.ModifierFlags)? {
        var modifiers: NSEvent.ModifierFlags = []
        var key: Key?

        if shortcut.contains("⌃") { modifiers.insert(.control) }
        if shortcut.contains("⌘") { modifiers.insert(.command) }
        if shortcut.contains("⌥") { modifiers.insert(.option) }
        if shortcut.contains("⇧") { modifiers.insert(.shift) }

        // Extracts the key character (e.g. "V") from the string.
        let letters = shortcut.replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
        if let lastChar = letters.last, let parsedKey = Key(string: String(lastChar)) {
            key = parsedKey
        }

        if let key = key {
            return (key, modifiers)
        }
        return nil
    }
}
