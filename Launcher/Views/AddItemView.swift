import SwiftUI
import LauncherCore

/// Three ways to add an app: from the bundled catalog, via a Shortcut, or by hand.
struct AddItemView: View {
    var body: some View {
        List {
            Section {
                NavigationLink("Pick from common apps") { CatalogPickerView() }
                NavigationLink("Via Shortcut (any app)") { ShortcutAddView() }
                NavigationLink("Custom URL or link") { CustomAddView() }
            } footer: {
                Text("iOS doesn't let apps see what's installed, so you choose the apps for your list. Common apps open with a link; a Shortcut works for any app.")
            }
        }
        .navigationTitle("Add app")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { DoneButton() }
    }
}

/// Tick any number of common apps and add them in one go.
struct CatalogPickerView: View {
    @Environment(LauncherModel.self) private var model
    @State private var query = ""
    @State private var picked: Set<CatalogEntry> = []
    private let catalog = AppCatalog.bundled()

    var body: some View {
        let added = Set(model.items.compactMap { item -> String? in
            if case .urlScheme(let scheme) = item.target { return scheme.lowercased() }
            return nil
        })
        List {
            ForEach(AppCatalog.search(catalog, query: query)) { entry in
                let isAdded = added.contains(entry.scheme.lowercased())
                Button {
                    if picked.contains(entry) { picked.remove(entry) } else { picked.insert(entry) }
                } label: {
                    HStack {
                        Image(systemName: isAdded || picked.contains(entry) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isAdded ? Color.secondary : (picked.contains(entry) ? Color.accentColor : Color.secondary))
                        Text(entry.name).foregroundStyle(isAdded ? .secondary : .primary)
                        Spacer()
                        if isAdded { Text("added").font(.footnote).foregroundStyle(.secondary) }
                    }
                }
                .disabled(isAdded)
                .accessibilityIdentifier("catalog.\(entry.name)")
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle("Pick apps")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(picked.isEmpty ? "Add" : "Add \(picked.count)") { addPicked() }
                    .disabled(picked.isEmpty)
                    .accessibilityIdentifier("catalog.add")
            }
        }
        .safeAreaInset(edge: .bottom) {
            Text("New apps go at the end of your widget. If an app doesn't open, add it with a Shortcut instead: this list's links come from the community and may be out of date.")
                .font(.footnote).foregroundStyle(.secondary)
                .padding().frame(maxWidth: .infinity).background(.bar)
        }
    }

    private func addPicked() {
        let entries = catalog.filter { picked.contains($0) } // catalog order (A–Z)
        let items = entries.map { LauncherItem(name: $0.name, target: .urlScheme($0.scheme)) }
        model.add(contentsOf: items)
        model.sheet = nil
    }
}

struct ShortcutAddView: View {
    @Environment(LauncherModel.self) private var model
    @State private var appName = ""

    var body: some View {
        Form {
            Section {
                TextField("App name, e.g. Spotify", text: $appName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("shortcutAdd.appName")
            } header: {
                Text("Which app?")
            } footer: {
                Text("Next you'll make a one-action Shortcut that opens it. This works for every app, including ones without a URL scheme.")
            }
            Section {
                NavigationLink("Next") {
                    ShortcutGuideView(appName: appName.trimmingCharacters(in: .whitespaces)) { item in
                        model.add(item)
                        model.sheet = nil
                    }
                }
                .disabled(appName.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityIdentifier("shortcutAdd.next")
            }
        }
        .navigationTitle("Via Shortcut")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CustomAddView: View {
    @Environment(LauncherModel.self) private var model
    @State private var name = ""
    @State private var link = ""

    private var target: LaunchTarget? { LaunchRouter.target(fromUserInput: link) }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.never)
                TextField("spotify:// or https://…", text: $link)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
            } footer: {
                Text("A URL scheme (like spotify://) opens the app directly. An https link opens in the browser, or in the app if it supports universal links.")
            }
            Section {
                TestLaunchButton(title: "Test", target: target)
                Button("Add") {
                    guard let target else { return }
                    model.add(LauncherItem(name: name.trimmingCharacters(in: .whitespaces), target: target))
                    model.sheet = nil
                }
                .disabled(target == nil || name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationTitle("Custom")
        .navigationBarTitleDisplayMode(.inline)
    }
}
