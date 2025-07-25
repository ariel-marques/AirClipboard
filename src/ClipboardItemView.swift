//
//  ClipboardItemView.swift
//  AirClipboard
//
//  SwiftUI view that renders a single item from the clipboard history.
//  Dynamically displays text, images, files or groups, adapting UI and actions to each type.
//  Demonstrates modular design, context menus, and macOS theming with SwiftUI.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ClipboardItemView: View {
    @AppStorage("playClickSound") private var playClickSound: Bool = true
    @EnvironmentObject var history: ClipboardHistory
    var item: ClipboardItem
    var isMostRecent: Bool
    @State private var isHovering = false

    var body: some View {
        ZStack {
            contentArea
                .overlay(fileGroupLabel, alignment: .topLeading)
                .overlay(timestampOverlay.allowsHitTesting(false), alignment: .topTrailing)
                .overlay(pinOverlay, alignment: .bottomTrailing)
                .overlay(menuOverlay, alignment: .trailing)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isHovering ? Color.accentColor : Color.clear, lineWidth: 0.5)
                        .animation(.easeInOut(duration: 0.3), value: isHovering)
                )
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .padding(.horizontal, 7)
        .listRowSeparator(.hidden)
    }

    /// Main clickable area of the card: triggers paste and feedback.
    private var contentArea: some View {
        HStack(alignment: .top) {
            contentView(for: item)
                .frame(maxWidth: 1100, minHeight: 50, alignment: .leading)
            Spacer()
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            if playClickSound {
                NSSound(named: "Blow")?.play()
            }
            PasteManager.shared.copyToPasteboard(item: item)
            NSApp.hide(nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                PasteManager.shared.performPaste()
            }
        }
    }

    /// Timestamp overlay (top-right)
    private var timestampOverlay: some View {
        Text(relativeDateFormatter.string(for: item.date) ?? "")
            .font(.caption2)
            .foregroundColor(.secondary)
            .opacity(0.5)
            .padding(.top, 6)
            .padding(.trailing, 10)
    }

    /// File group count overlay (top-left)
    private var fileGroupLabel: some View {
        Group {
            if case .fileGroup(let urls) = item.type {
                Text(LocalizedStringKey("file_group_count \(urls.count)"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(0.5)
                    .padding(.top, 6)
                    .padding(.leading, 10)
            }
        }
    }

    /// Pin/unpin overlay (bottom-right)
    private var pinOverlay: some View {
        Group {
            if item.isPinned {
                Button(action: {
                    history.togglePin(for: item)
                }) {
                    Image(systemName: "pin")
                        .foregroundColor(.blue)
                        .padding(1)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                .padding(.bottom, 6)
            }
        }
    }

    /// Contextual menu overlay (right side)
    private var menuOverlay: some View {
        Menu {
            Button {
                PasteManager.shared.copyToPasteboard(item: item)
            } label: {
                Label("copy_again", systemImage: "doc.on.doc")
            }

            Button {
                history.togglePin(for: item)
            } label: {
                Label(item.isPinned ? "unpin" : "pin_to_top", systemImage: item.isPinned ? "pin.slash.fill" : "pin.fill")
            }
            Divider()
            if !isMostRecent {
                Button(role: .destructive) {
                    history.delete(item: item)
                } label: {
                    Label("delete", systemImage: "trash.fill")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.primary, .secondary)
                .font(.title2)
                .padding(8)
        }
        .frame(width: 25)
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    /// Renders each content type (text, image, file, or group) with the appropriate layout.
    @ViewBuilder
    private func contentView(for item: ClipboardItem) -> some View {
        switch item.type {
        case .text(let value):
            let formattedValue = value.replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
            HStack(spacing: 8) {
                if let favicon = item.type.faviconURL {
                    AsyncImage(url: favicon) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .frame(width: 16, height: 16)
                                .cornerRadius(3)
                        default:
                            Image(systemName: "link")
                                .foregroundColor(.accentColor)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
                Text(formattedValue)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .frame(maxWidth: 335, alignment: .leading)
                Spacer()
            }
        case .file(let url):
            VStack(spacing: 4) {
                FileIconView(fileURL: url)
                    .frame(width: 32, height: 32)
                Text(url.lastPathComponent)
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(width: 70)
            }
            .help(url.lastPathComponent)
        case .image(let data):
            if let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 60)
            }
        case .fileGroup(let urls):
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    ForEach(urls.prefix(6), id: \.self) { url in
                        FileIconView(fileURL: url)
                            .frame(width: 40, height: 40)
                            .cornerRadius(2)
                            .help(url.lastPathComponent)
                    }
                    if urls.count > 6 {
                        Text("+\(urls.count - 6)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .opacity(0.5)
                            .padding(.leading, 1)
                            .help(urls.dropFirst(6).map { $0.lastPathComponent }.joined(separator: "\n"))
                    }
                }
                .padding(.leading, 4)
            }
        }
    }

    @AppStorage("selectedLanguage") private var selectedLanguage: String = "system"

    /// Date formatter that adapts to user's selected language.
    private var relativeDateFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated

        switch selectedLanguage {
        case "pt":
            formatter.locale = Locale(identifier: "pt_BR")
        case "en":
            formatter.locale = Locale(identifier: "en_US")
        default:
            formatter.locale = Locale.current
        }

        return formatter
    }
}

#Preview {
    ContentView()
}
