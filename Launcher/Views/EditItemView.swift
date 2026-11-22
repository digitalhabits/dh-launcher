import SwiftUI
import LauncherCore

struct EditItemView: View {
    @Environment(LauncherModel.self) private var model
    @State private var draft: LauncherItem
    @State private var kind: Kind
    @State private var value: String
    @State private var confirmDelete = false

    enum Kind: String, CaseIterable, Identifiable {
        case scheme = "URL scheme", shortcut = "Shortcut", web = "Web link"
        var id: String { rawValue }
    }

    init(item: LauncherItem) {
        _draft = State(initialValue: item)
        switch item.target {
        case .urlScheme(let s): _kind = State(initialValue: .scheme); _value = State(initialValue: s)
        case .shortcut(let n): _kind = State(initialValue: .shortcut); _value = State(initialValue: n)
        case .web(let u): _kind = State(initialValue: .web); _value = State(initialValue: u.absoluteString)
        }
    }

    private var target: LaunchTarget? {
        let v = value.trimmingCharacters(in: .whitespacesAndNewlines)
        switch kind {
        case .scheme:
            return LaunchRouter.destination(for: .urlScheme(v)) == nil ? nil : .urlScheme(v)
        case .shortcut:
            return v.isEmpty ? nil : .shortcut(name: v)
        case .web:
            guard let url = URL(string: v), LaunchRouter.destination(for: .web(url)) != nil, url.host != nil else { return nil }
            return .web(url)
        }
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $draft.name)
                    .accessibilityIdentifier("edit.name")
            }
            Section {
                Picker("Opens via", selection: $kind) {
                    ForEach(Kind.allCases) { Text($0.rawValue).tag($0) }
                }
                TextField(placeholder, text: $value)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("edit.value")
                TestLaunchButton(title: "Test", target: target)
                if kind == .shortcut {
                    NavigationLink("Shortcut setup guide") {
                        ShortcutGuideView(appName: draft.name, shortcutName: value, onSave: nil)
                    }
                }
            } header: {
                Text("Target")
            } footer: {
                if target == nil { Text("Enter a valid \(kind.rawValue.lowercased()).").foregroundStyle(.red) }
            }
            Section {
                Toggle("Show on home screen", isOn: $draft.onHomeScreen)
            }
            Section {
                Button("Delete", role: .destructive) { confirmDelete = true }
            }
        }
        .navigationTitle("Edit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { model.sheet = nil }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    guard let target else { return }
                    draft.target = target
                    draft.name = draft.name.trimmingCharacters(in: .whitespaces)
                    model.update(draft)
                    model.sheet = nil
                }
                .disabled(target == nil || draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityIdentifier("edit.save")
            }
        }
        .confirmationDialog("Delete \(draft.name)?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                model.delete(id: draft.id)
                model.sheet = nil
            }
        }
    }

    private var placeholder: String {
        switch kind {
        case .scheme: "spotify://"
        case .shortcut: "Open Spotify"
        case .web: "https://…"
        }
    }
}
