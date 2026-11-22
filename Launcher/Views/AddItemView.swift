import SwiftUI
import LauncherCore

/// Three ways to add an app: from the bundled catalog, via a Shortcut, or by hand.
struct AddItemView: View {
    var body: some View {
        List {
            Section {
                NavigationLink("From catalog") { CatalogPickerView() }
                NavigationLink("Via Shortcut (any app)") { ShortcutAddView() }
                NavigationLink("Custom URL or link") { CustomAddView() }
            } footer: {
                Text("iOS doesn't let apps see what's installed, so you build your own list. The catalog knows URL schemes for common apps; a Shortcut works for any app.")
            }
        }
        .navigationTitle("Add app")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { DoneButton() }
    }
}

struct CatalogPickerView: View {
    @Environment(LauncherModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    private let catalog = AppCatalog.bundled()

    var body: some View {
        List {
            ForEach(AppCatalog.search(catalog, query: query)) { entry in
                Button {
                    model.add(LauncherItem(name: entry.name, target: .urlScheme(entry.scheme)))
                    model.sheet = nil
                } label: {
                    HStack {
                        Text(entry.name).foregroundStyle(.primary)
                        Spacer()
                        Text(entry.scheme).font(.footnote.monospaced()).foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier("catalog.\(entry.name)")
            }
        } 
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle("Catalog")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Text("Schemes are community-maintained and may be out of date. If an app doesn't open, add it via Shortcut instead.")
                .font(.footnote).foregroundStyle(.secondary)
                .padding().frame(maxWidth: .infinity).background(.bar)
        }
    }
}

struct ShortcutAddView: View {
    @Environment(LauncherModel.self) private var model
    @State private var appName = ""

    var body: some View {
        Form {
            Section {
                TextField("App name, e.g. Spotify", text: $appName)
                    .textInputAutocapitalization(.words)
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
