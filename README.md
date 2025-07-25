# AirClipboard — Swift/macOS (Public Sample Code)

This repository contains **public sample code** from the development of [AirClipboard](https://airclipboard.app), a fully native and highly polished clipboard manager for macOS.

> **Note:**  
> This is a public sample version. No license, backend, or sensitive code is included.  
> The main goal is to demonstrate my approach to modern Swift architecture, system integration, and UX-focused development for macOS.

---

## What’s included?

- **Core clipboard history logic**  
  Deduplication, pin/unpin, trimming, persistence, and reactivity using SwiftUI's `ObservableObject`.

- **Pasteboard integration**  
  Support for text, images (with Finder compatibility), single files, and file groups — all using native macOS APIs.

- **Modular UI in SwiftUI**  
  Examples of modular, reusable components (e.g., dynamic item cards, preferences window, contextual menus) with support for light/dark mode and localization.

- **Preferences & state management**  
  Centralized settings and global state manager (`AppEnvironment.swift`), demonstrating best practices for UserDefaults/@AppStorage and reactive updates.

- **Customizable global shortcut**  
  Global keyboard shortcut registration and parsing, allowing users to define their own hotkey to launch the app.

---

## Why Public Sample Code?

- This repo is designed for **portfolio and demonstration purposes**.  
- It does **not** contain the complete, commercial source code.  
- Code related to **license validation, backend APIs, payment, and security** has been removed or mocked for safety and privacy.
- If you are a recruiter, company, or collaborator interested in more details or private code review, [please contact me](mailto:hi@airclipboard.app).

---

## Repo structure
src/
-  ClipboardHistory.swift      # Clipboard history core logic
-  PasteManager.swift          # System clipboard (NSPasteboard) integration
-  ClipboardItemView.swift     # Modular, adaptive SwiftUI view for history items
-  PreferencesView.swift       # SwiftUI preferences/settings window
-  AppEnvironment.swift        # Global state and settings manager
-  HotkeyManager.swift         # Global hotkey registration and parsing
README.md

---

## Quick sample

Here’s an example of how clipboard history logic is managed:

```swift
func addItem(_ item: ClipboardItem) {
    if let first = history.first, !first.isPinned, item.isDuplicate(of: first) { return }
    if let index = history.firstIndex(where: { $0.isDuplicate(of: item) && !$0.isPinned }) {
        history.remove(at: index)
    }
    history.insert(item, at: 0)
    lastInsertedID = item.id
    sortByPinnedAndDate()
    let pinned = history.filter { $0.isPinned }
    let unpinned = history.filter { !$0.isPinned }
    let trimmed = Array(unpinned.prefix(historyLimit))
    self.history = pinned + trimmed
    storage.saveHistory(history)
}
```

---

## Screenshot

[<img src="https://ariel.works/projects/assets/img/dark-light-mode-airclipboard.png" alt="AirClipboard dark and light mode" width="400"/>](https://ariel.works/projects/assets/img/dark-light-mode-airclipboard.png)

---

## Want to know more?

- Full app, design process, and UX/UI rationale available at [ariel.works/projects/airclipboard](https://ariel.works/projects/airclipboard)
- For questions, collaboration, or private code review, reach out to me!

**Thank you for checking out this project!**

---
