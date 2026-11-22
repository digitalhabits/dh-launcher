import SwiftUI
import LauncherCore

/// The root screen: the widget's list, as plain text, in the same order. Tap a
/// name to open it; touch and hold to edit or remove it. Apps past what the
/// large widget can hold are grey and marked. There is no search: iOS can't
/// tell apps what is installed, and its own Search already finds everything.
struct DrawerView: View {
    @Environment(LauncherModel.self) private var model
    @Environment(\.palette) private var palette
    @State private var pendingDelete: LauncherItem?

    var body: some View {
        let settings = model.settings
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: settings.alignment.horizontal, spacing: 6) {
                    ForEach(Array(model.items.enumerated()), id: \.element.id) { index, item in
                        row(item, fits: WidgetCapacity.fits(position: index, size: .large, settings: settings), settings: settings)
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
                .padding(.top, 48)
                .padding(.bottom, 8)
            }

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
            .padding(.vertical, 6)
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
            Text("touch and hold a name to edit it")
                .font(model.settings.font(size: 13, weight: .regular))
                .foregroundStyle(palette.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("drawer.hint")
            HStack(spacing: 22) {
                footerLink("add app") { model.sheet = .add }
                footerLink("home screen layout") { model.sheet = .homeScreen }
                footerLink("settings") { model.sheet = .settings }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 28)
        .padding(.vertical, 10)
    }

    private func footerLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(model.settings.font(size: 15, weight: .regular))
            .foregroundStyle(palette.secondary)
            .accessibilityIdentifier("drawer.footer.\(title)")
    }
}
