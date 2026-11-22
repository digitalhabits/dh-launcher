import SwiftUI
import UIKit
import LauncherCore

/// What a Shortcut opens: an installed app ("Open App" action) or a website
/// ("Open URLs" action). The guides differ only in steps 2 and 3.
enum ShortcutKind: String, Hashable {
    case app, website
}

/// One short guide per kind: a name, then numbered steps with a picture of the
/// Shortcuts screen and the button to tap circled. Ends with Test and Add.
/// `onSave` is nil when the guide is opened for reference (from How to use or Edit).
struct ShortcutGuideView: View {
    let kind: ShortcutKind
    let onSave: ((LauncherItem) -> Void)?
    @State private var name: String
    /// Set when editing an existing item whose shortcut may have another name.
    private let fixedShortcutName: String?
    @State private var copied = false
    @Environment(\.openURL) private var openURL
    @FocusState private var nameFocused: Bool

    init(kind: ShortcutKind, name: String = "", shortcutName: String? = nil, onSave: ((LauncherItem) -> Void)?) {
        self.kind = kind
        self.onSave = onSave
        self.fixedShortcutName = shortcutName
        _name = State(initialValue: name)
    }

    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }
    private var shortcutName: String {
        fixedShortcutName ?? LaunchRouter.suggestedShortcutName(forApp: trimmed.isEmpty ? (kind == .app ? "Spotify" : "YouTube") : trimmed)
    }
    private var appName: String { Bundle.main.displayName }

    var body: some View {
        Form {
            if onSave != nil {
                Section {
                    TextField(kind == .app ? "e.g. Spotify" : "e.g. YouTube", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($nameFocused)
                        .accessibilityIdentifier("shortcutGuide.name")
                } header: {
                    Text(kind == .app ? "Which app?" : "Which website?")
                } footer: {
                    Text("This is the name on your widget.")
                }
            }

            Section {
                step(1, "Copy the shortcut name, then open Shortcuts.") {
                    // Own button styles, so each has its own tap area inside the Form row.
                    VStack(spacing: 8) {
                        Button {
                            UIPasteboard.general.string = shortcutName
                            copied = true
                        } label: {
                            Label(copied ? "Copied \"\(shortcutName)\"" : "Copy \"\(shortcutName)\"",
                                  systemImage: copied ? "checkmark" : "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        .accessibilityIdentifier("shortcutGuide.copy")
                        Button {
                            openURL(URL(string: "shortcuts://create-shortcut")!)
                        } label: {
                            Label("Open Shortcuts", systemImage: "arrow.up.forward.app")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("shortcutGuide.openShortcuts")
                    }
                    .font(.subheadline.weight(.semibold))
                    .controlSize(.large)
                }
                switch kind {
                case .app:
                    step(2, "Tap **Open App**. Not in the list? Type \"Open App\" in the search box.", image: "guide-open-app")
                    step(3, "Tap the faded word **App** and pick **\(trimmed.isEmpty ? "the app" : trimmed)**.", image: "guide-pick-app")
                case .website:
                    step(2, "Type **Open URLs** in the search box and tap it.", image: "guide-open-urls")
                    step(3, "Tap the faded word **URL** and type the website's address, like youtube.com.", image: "guide-type-url")
                }
                step(4, "Tap the name at the top, choose **Rename**, paste, and tap **Done**. Check it now says **\(shortcutName)**.", image: "guide-rename")
                step(5, "Tap **‹** to save. Then tap **◀ \(appName)** at the top left to come back here.")
                step(6, "Tap **Test** below. The first time, iOS asks for permission: tap **Always Allow**.",
                     image: kind == .app ? "guide-allow" : "guide-allow-website")
            }

            Section {
                TestLaunchButton(title: "Test", target: .shortcut(name: shortcutName))
                    .accessibilityIdentifier("shortcutGuide.test")
                if let onSave {
                    Button(trimmed.isEmpty ? "Add" : "Add \(trimmed)") {
                        onSave(LauncherItem(name: trimmed, target: .shortcut(name: shortcutName)))
                    }
                    .disabled(trimmed.isEmpty)
                    .accessibilityIdentifier("shortcutGuide.add")
                }
            } footer: {
                Text(kind == .app
                     ? "If Test opens the app, it works. If Shortcuts shows an error, the shortcut's name doesn't match."
                     : "If Test opens the website, it works. If Shortcuts shows an error, the shortcut's name doesn't match.")
            }
        }
        .navigationTitle(kind == .app ? "Add an app" : "Add a website")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: name) { copied = false }
        .onAppear { if onSave != nil && trimmed.isEmpty { nameFocused = true } }
    }

    private func step(_ n: Int, _ text: LocalizedStringKey, image: String? = nil) -> some View {
        step(n, text, image: image) { EmptyView() }
    }

    private func step<Extra: View>(_ n: Int, _ text: LocalizedStringKey, image: String? = nil, @ViewBuilder extra: () -> Extra) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(n)").font(.body.monospacedDigit().weight(.semibold)).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10) {
                Text(text)
                extra()
                if let image {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.3)))
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

extension Bundle {
    var displayName: String {
        (object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "the launcher"
    }
}
