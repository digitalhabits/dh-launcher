import SwiftUI
import LauncherCore

/// Three ways to add: tick common apps, or make a one-step Shortcut for any app or website.
struct AddItemView: View {
    @Environment(LauncherModel.self) private var model

    var body: some View {
        List {
            Section {
                NavigationLink("Pick from common apps") { CatalogPickerView() }
                NavigationLink("Add any app") { ShortcutGuideView(kind: .app, onSave: save) }
                NavigationLink("Add a website") { ShortcutGuideView(kind: .website, onSave: save) }
            } footer: {
                Text("iOS doesn't let apps see what's installed, so you choose what goes on your widget. Any app or website that isn't in the common list takes a one-step Shortcut, and \(Bundle.main.displayName) shows you how.")
            }
        }
        .navigationTitle("Add app")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { DoneButton() }
    }

    private func save(_ item: LauncherItem) {
        model.add(item)
        model.sheet = nil
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
            Text("New apps go at the end of your widget. If one doesn't open when you tap it, add it with a Shortcut instead.")
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
