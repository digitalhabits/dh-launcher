import SwiftUI
import LauncherCore

/// The root screen: every item as plain text, with a search field that has
/// focus (keyboard up) whenever the drawer appears.
struct DrawerView: View {
    @Environment(LauncherModel.self) private var model
    @Environment(\.palette) private var palette
    @Environment(\.scenePhase) private var scenePhase
    @State private var query = ""
    @FocusState private var searchFocused: Bool
    @State private var pendingDelete: LauncherItem?

    private var results: [LauncherItem] {
        Search.filter(model.items, query: query, name: \.name)
    }

    var body: some View {
        let settings = model.settings
        VStack(spacing: 0) {
            TextField("", text: $query, prompt: Text("search").foregroundStyle(palette.secondary))
                .font(model.settings.font(size: 20))
                .foregroundStyle(palette.foreground)
                .multilineTextAlignment(settings.alignment.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .focused($searchFocused)
                .onSubmit { if let first = results.first { launch(first) } }
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .accessibilityIdentifier("drawer.search")

            ScrollView {
                LazyVStack(alignment: settings.alignment.horizontal, spacing: 6) {
                    ForEach(results) { item in
                        row(item, settings: settings)
                    }
                    if model.items.isEmpty {
                        Button("add your first app") { model.sheet = .add }
                            .font(settings.drawerFont)
                            .foregroundStyle(palette.secondary)
                            .padding(.vertical, 8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: settings.alignment.frame)
                .padding(.horizontal, 28)
                .padding(.vertical, 8)
            }
            .scrollDismissesKeyboard(.interactively)

            footer
        }
        .onAppear { focusSearch() }
        .onChange(of: model.drawerResetToken) { reset() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, model.sheet == nil { focusSearch() }
        }
        .onChange(of: model.sheet) { _, sheet in
            // Give the keyboard to the sheet; come back clean when it closes.
            if sheet == nil { reset() } else { searchFocused = false }
        }
        .onChange(of: query) { _, newValue in autoLaunchIfSingleMatch(newValue) }
        .confirmationDialog(
            "Delete \(pendingDelete?.name ?? "")?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let item = pendingDelete { model.delete(id: item.id) }
                pendingDelete = nil
            }
        }
    }

    private func row(_ item: LauncherItem, settings: LauncherSettings) -> some View {
        Button { launch(item) } label: {
            Text(settings.displayName(item.name))
                .font(settings.drawerFont)
                .foregroundStyle(palette.foreground)
                .multilineTextAlignment(settings.alignment.text)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Edit", systemImage: "pencil") { model.sheet = .edit(item.id) }
            Button(item.onHomeScreen ? "Remove from home screen" : "Show on home screen",
                   systemImage: item.onHomeScreen ? "minus.circle" : "plus.circle") {
                model.toggleHomeScreen(id: item.id)
            }
            Button("Delete", systemImage: "trash", role: .destructive) { pendingDelete = item }
        }
        .accessibilityIdentifier("drawer.item.\(item.name)")
    }

    private var footer: some View {
        HStack(spacing: 22) {
            footerLink("add") { model.sheet = .add }
            footerLink("home screen") { model.sheet = .homeScreen }
            footerLink("settings") { model.sheet = .settings }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 10)
    }

    private func footerLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(model.settings.font(size: 15, weight: .regular))
            .foregroundStyle(palette.secondary)
            .accessibilityIdentifier("drawer.footer.\(title)")
    }

    // MARK: Behaviour

    private func launch(_ item: LauncherItem) {
        searchFocused = false
        query = ""
        model.launch(item)
    }

    /// Olauncher behaviour: when typing narrows the list to exactly one item, open it.
    private func autoLaunchIfSingleMatch(_ text: String) {
        guard model.settings.autoLaunchSingleMatch,
              !text.trimmingCharacters(in: .whitespaces).isEmpty
        else { return }
        let matches = Search.filter(model.items, query: text, name: \.name)
        if matches.count == 1 { launch(matches[0]) }
    }

    private func reset() {
        query = ""
        focusSearch()
    }

    private func focusSearch() {
        // Focus only sticks once the view is in the window and any sheet has
        // finished animating away, so wait a moment before asking for it.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            guard model.sheet == nil, model.phase == .drawer else { return }
            searchFocused = true
        }
    }
}
