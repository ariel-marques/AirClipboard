//
//  PasteManager.swift
//  AirClipboard
//
//  Created by Ariel Marques on 12/04/25.
//
//  Handles the core copy and paste logic for AirClipboard.
//  Integrates with macOS NSPasteboard to support text, images, files, and file groups.
//  Demonstrates Swift patterns for system integration and extensibility.
//
import AppKit

class PasteManager {
    static let shared = PasteManager()

    private init() {}

    /// Copies any clipboard item (text, image, file, or group) to the system pasteboard.
    func copyToPasteboard(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.type {
        case .text(let value):
            // Copies text directly to the pasteboard.
            pasteboard.setString(value, forType: .string)

        case .image(let data):
            // For images, creates a temporary PNG file if possible, allowing paste as file in Finder.
            if let tempURL = writeImageAsTempFile(data) {
                pasteboard.writeObjects([tempURL as NSURL])
            } else if let image = NSImage(data: data) {
                pasteboard.writeObjects([image])
            }

        case .file(let url):
            // Copies a single file (URL) to the pasteboard.
            pasteboard.writeObjects([url as NSURL])

        case .fileGroup(let urls):
            // Handles groups of files for batch copying/pasting.
            let nsURLs = urls.map { $0 as NSURL }
            pasteboard.writeObjects(nsURLs)
        }

        // print("📋 Content copied to pasteboard") // (Commented for clean example)
    }

    /// Triggers a simulated paste (⌃⌘V) in the target application.
    func performPaste() {
        PasteStrategy.performPaste() // Simulates Cmd+V
    }

    /// Writes image data as a temporary PNG file, so Finder can accept it as a file drop.
    private func writeImageAsTempFile(_ data: Data) -> URL? {
        let filename = "AirClipboard_Image_\(UUID().uuidString).png"
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            // print("⚠️ Failed to save temporary image file: \(error)") // (Commented for clean example)
            return nil
        }
    }
}
