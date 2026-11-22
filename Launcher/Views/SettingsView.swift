import SwiftUI
import LauncherCore

struct SettingsView: View {
    @Environment(LauncherModel.self) private var model

    var body: some View {
        let s = model.settings
        Form {
            Section("Look") {
                Picker("Alignment", selection: binding(\.alignment, s.alignment)) {
                    Text("Left").tag(LauncherSettings.Alignment.leading)
                    Text("Centre").tag(LauncherSettings.Alignment.center)
                    Text("Right").tag(LauncherSettings.Alignment.trailing)
                }
                Picker("Text size", selection: binding(\.textSize, s.textSize)) {
                    Text("Small").tag(LauncherSettings.TextSize.small)
                    Text("Medium").tag(LauncherSettings.TextSize.medium)
                    Text("Large").tag(LauncherSettings.TextSize.large)
                }
                Picker("Font", selection: binding(\.fontStyle, s.fontStyle)) {
                    Text("Schibsted Grotesk").tag(LauncherSettings.FontStyle.brand)
                    Text("System").tag(LauncherSettings.FontStyle.system)
                }
                Picker("Theme", selection: binding(\.theme, s.theme)) {
                    Text("Black").tag(LauncherSettings.Theme.black)
                    Text("White").tag(LauncherSettings.Theme.white)
                }
                Toggle("Lowercase names", isOn: binding(\.lowercaseNames, s.lowercaseNames))
                Toggle("Show date in widget", isOn: binding(\.showDate, s.showDate))
            }
            Section {
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
            } footer: {
                Text("Free and open source. Inspired by Olauncher for Android; no code is shared.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { DoneButton() }
    }

    private func binding<T>(_ path: WritableKeyPath<LauncherSettings, T>, _ current: T) -> Binding<T> where T: Sendable {
        Binding(get: { model.settings[keyPath: path] }, set: { newValue in model.updateSettings { $0[keyPath: path] = newValue } })
    }
}
