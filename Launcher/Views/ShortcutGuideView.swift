import SwiftUI
import UIKit
import LauncherCore

/// Step-by-step guide for making an "Open <App>" Shortcut, with the exact name
/// to copy, a button into Shortcuts, and a Test button. When `onSave` is set,
/// it ends with adding the item.
struct ShortcutGuideView: View {
    let appName: String
    let onSave: ((LauncherItem) -> Void)?
    @State private var shortcutName: String
    @State private var copied = false
    @Environment(\.openURL) private var openURL

    init(appName: String, shortcutName: String? = nil, onSave: ((LauncherItem) -> Void)?) {
        self.appName = appName
        self.onSave = onSave
        let app = appName.isEmpty ? "<App>" : appName
        _shortcutName = State(initialValue: shortcutName ?? LaunchRouter.suggestedShortcutName(forApp: app))
    }

    private var appLabel: String { appName.isEmpty ? "the app" : appName }
    private var trimmedName: String { shortcutName.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        Form {
            Section {
                TextField("Shortcut name", text: $shortcutName)
                    .autocorrectionDisabled()
                    .font(.body.monospaced())
                    .accessibilityIdentifier("shortcutGuide.name")
                Button(copied ? "Copied" : "Copy name") {
                    UIPasteboard.general.string = trimmedName
                    copied = true
                }
                .accessibilityIdentifier("shortcutGuide.copy")
            } header: {
                Text("Shortcut name")
            } footer: {
                Text("The Shortcut must be named exactly this. Capitals and spaces count.")
            }

            Section("Steps") {
                step(1, "Tap **Copy name** above.")
                step(2, "Tap **Open Shortcuts** below. A new, empty shortcut opens.")
                step(3, "In the list at the bottom, tap **Open App**. If it isn't there, type \"Open App\" into **Search Actions**.")
                step(4, "Tap the faded word **App** in the action and choose **\(appLabel)**.")
                step(5, "Tap the title **New Shortcut** at the top and choose **Rename**. With the old name selected, tap it again, choose **Paste**, then tap **Done** on the keyboard.")
                step(6, "Tap **‹** at the top left to save it. Come back here by tapping **◀ \(Bundle.main.displayName)** in the status bar.")
                step(7, "Tap **Test**. The first time, Shortcuts asks whether the shortcut may output an app: tap **Always Allow**, otherwise it asks every time. If **\(appLabel)** then opens, it works: come back here and tap **Add**.")
                Button("Open Shortcuts") {
                    openURL(URL(string: "shortcuts://create-shortcut")!)
                }
                .accessibilityIdentifier("shortcutGuide.openShortcuts")
            }

            Section {
                TestLaunchButton(title: "Test", target: trimmedName.isEmpty ? nil : .shortcut(name: trimmedName))
                    .accessibilityIdentifier("shortcutGuide.test")
                if let onSave {
                    Button("Add \(appName)") {
                        onSave(LauncherItem(name: appName, target: .shortcut(name: trimmedName)))
                    }
                    .disabled(trimmedName.isEmpty || appName.isEmpty)
                    .accessibilityIdentifier("shortcutGuide.add")
                }
            } footer: {
                Text("If Test opens Shortcuts with an error, the name doesn't match. Running a shortcut briefly shows a banner at the top of the screen; that's iOS, not this app.")
            }
        }
        .navigationTitle(appName.isEmpty ? "Shortcut guide" : "Add \(appName)")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: shortcutName) { copied = false }
    }

    private func step(_ n: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(n)").font(.body.monospacedDigit()).foregroundStyle(.secondary)
            Text(text)
        }
    }
}

extension Bundle {
    var displayName: String {
        (object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "the launcher"
    }
}
