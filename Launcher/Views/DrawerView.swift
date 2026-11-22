import SwiftUI
import LauncherCore

/// The root screen: the widget's list, as plain text, in the same order. Tap a
/// name to open it; touch and hold to edit or remove it, or drag it to reorder. Apps past what the
/// large widget can hold are grey and marked. There is no search: iOS can't
/// tell apps what is installed, and its own Search already finds everything.
struct DrawerView: View {
    @Environment(LauncherModel.self) private var model
    @Environment(\.palette) private var palette
    @State private var pendingDelete: LauncherItem?

    var body: some View {
        let settings = model.settings
        VStack(spacing: 0) {
            // A List, not a stack, so that names can be dragged to a new order:
            // touch and hold, then move. Holding still opens Edit and Remove.
            List {
                ForEach(Array(model.items.enumerated()), id: \.element.id) { index, item in
                    row(item, fits: WidgetCapacity.fits(position: index, size: .large, settings: settings), settings: settings)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 3, leading: 28, bottom: 3, trailing: 28))
                }
                .onMove { model.move(fromOffsets: $0, toOffset: $1) }
                if !model.items.isEmpty {
                    Text("touch and hold a name to edit it, or drag it to reorder")
                        .font(settings.font(size: 13, weight: .regular))
                        .foregroundStyle(palette.secondary.opacity(0.8))
                        .multilineTextAlignment(settings.alignment.text)
                        .frame(maxWidth: .infinity, alignment: settings.alignment.frame)
                        .padding(.top, 14 * LauncherSettings.screenScale)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 3, leading: 28, bottom: 3, trailing: 28))
                        .accessibilityIdentifier("drawer.hint")
                }
                if model.items.isEmpty {
                    Button("add your first app") { model.sheet = .add }
                        .font(settings.drawerFont)
                        .foregroundStyle(palette.secondary)
                        .frame(maxWidth: .infinity, alignment: settings.alignment.frame)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 48, for: .scrollContent)

            footer
        }
        .confirmationDialog(
            "Remove \(pendingDelete.map { settings.displayName($0.name) } ?? "")?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let item = pendingDelete { model.delete(id: item.id) }
                pendingDelete = nil
            }
        } message: {
            Text("It leaves your widget. The app itself stays on your iPhone.")
        }
    }

    private func row(_ item: LauncherItem, fits: Bool, settings: LauncherSettings) -> some View {
        Button { model.launch(item) } label: {
            VStack(alignment: settings.alignment.horizontal, spacing: 0) {
                Text(settings.displayName(item.name))
                    .font(settings.drawerFont)
                    .foregroundStyle(fits ? palette.foreground : palette.secondary)
                    .multilineTextAlignment(settings.alignment.text)
                if !fits {
                    Text("doesn't fit on the widget")
                        .font(settings.font(size: 13))
                        .foregroundStyle(palette.secondary)
                }
            }
            .padding(.vertical, 6 * LauncherSettings.screenScale)
            .frame(maxWidth: .infinity, alignment: settings.alignment.frame)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Edit", systemImage: "pencil") { model.sheet = .edit(item.id) }
            Button("Remove", systemImage: "minus.circle", role: .destructive) { pendingDelete = item }
        }
        .accessibilityIdentifier("drawer.item.\(item.name)")
    }

    private var footer: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack(spacing: 22 * LauncherSettings.screenScale) {
                footerLink("add app") { model.sheet = .add }
                footerLink("how to use") { model.sheet = .setupGuide }
                footerLink("settings") { model.sheet = .settings }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 28)
        .padding(.vertical, 10 * LauncherSettings.screenScale)
    }

    private func footerLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(model.settings.font(size: 15, weight: .regular))
            .foregroundStyle(palette.secondary)
            .accessibilityIdentifier("drawer.footer.\(title)")
    }
}
