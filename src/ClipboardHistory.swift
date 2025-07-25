//
//  ClipboardHistory.swift
//  AirClipboard
//
//  Created by Ariel Marques on 12/04/25.
//
//  Manages the clipboard history: deduplication, pin/unpin, limit, and local persistence.
//  Demonstrates SwiftUI integration (ObservableObject) and architecture patterns for native macOS apps.
//

import Foundation
import SwiftUI

class ClipboardHistory: ObservableObject {
    @Published var pinnedScrollTargetID: UUID?
    @Published var lastInsertedID: UUID?
    @Published var history: [ClipboardItem] = []
    private let storage = ClipboardStorage()

    @AppStorage("historyLimit") private var historyLimit: Int = 50

    init() {
        // Loads previously saved history and sorts by pin/date on launch.
        self.history = storage.loadHistory()
        sortByPinnedAndDate()
    }

    /// Adds a new item to history, eliminates duplicates, and applies the user-defined limit.
    func addItem(_ item: ClipboardItem) {
        // Ignore if duplicate of the first (unpinned) item.
        if let first = history.first, !first.isPinned, item.isDuplicate(of: first) {
            return
        }

        // Remove previous (unpinned) duplicates.
        if let index = history.firstIndex(where: { $0.isDuplicate(of: item) && !$0.isPinned }) {
            history.remove(at: index)
        }

        // Insert the new item at the top.
        history.insert(item, at: 0)
        lastInsertedID = item.id

        sortByPinnedAndDate()

        // Keep pinned items and only the most recent unpinned, up to the limit.
        let pinned = history.filter { $0.isPinned }
        let unpinned = history.filter { !$0.isPinned }
        let trimmed = Array(unpinned.prefix(historyLimit))

        self.history = pinned + trimmed
        storage.saveHistory(history)
    }

    /// Toggles pin/unpin for a given item and saves the updated order.
    func togglePin(for item: ClipboardItem) {
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            history[index].isPinned.toggle()
            sortByPinnedAndDate()
            pinnedScrollTargetID = history[index].id
            storage.saveHistory(history)
        }
    }

    /// Clears the entire clipboard history.
    func clearHistory() {
        history.removeAll()
        storage.saveHistory(history)
    }

    /// Deletes a specific item from history.
    func delete(item: ClipboardItem) {
        if item.id == lastInsertedID {
            lastInsertedID = nil
        }
        history.removeAll { $0.id == item.id }
        storage.saveHistory(history)
    }

    /// Sorts items so that pinned ones come first, each group ordered by date (most recent first).
    private func sortByPinnedAndDate() {
        history.sort {
            if $0.isPinned == $1.isPinned {
                return $0.date > $1.date
            }
            return $0.isPinned && !$1.isPinned
        }
    }
}
