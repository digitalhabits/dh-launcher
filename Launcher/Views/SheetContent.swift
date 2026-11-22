import SwiftUI
import LauncherCore

/// Routes a `Sheet` to its view, each inside its own navigation stack.
struct SheetContent: View {
    let sheet: Sheet
    @Environment(LauncherModel.self) private var model

    var body: some View {
        NavigationStack {
            switch sheet {
            case .add:
                AddItemView()
            case .edit(let id):
                if let item = model.item(id: id) {
                    EditItemView(item: item)
                } else {
                    Text("This item no longer exists.")
                }
            case .settings:
                SettingsView()
            case .setupGuide:
                SetupGuideView()
            case .shortcutGuide(let appName):
                ShortcutGuideView(kind: .app, name: appName) { new in
                    // From "Couldn't open": switch the existing item to the Shortcut.
                    if var existing = model.items.first(where: { $0.name == appName }) {
                        existing.target = new.target
                        model.update(existing)
                    } else {
                        model.add(new)
                    }
                    model.sheet = nil
                }
            }
        }
    }
}

/// A "Done" button for the top-left of every sheet.
struct DoneButton: ToolbarContent {
    @Environment(\.dismiss) private var dismiss
    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Done") { dismiss() }
        }
    }
}

/// Opens a URL from inside a sheet and reports whether iOS accepted it.
struct TestLaunchButton: View {
    let title: String
    let target: LaunchTarget?
    @Environment(\.openURL) private var openURL
    @State private var failed = false

    var body: some View {
        Button(title) {
            guard let target, let url = LaunchRouter.destination(for: target) else {
                failed = true
                return
            }
            openURL(url) { accepted in failed = !accepted }
        }
        .disabled(target == nil)
        .alert("Couldn't open it", isPresented: $failed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The app may not be installed, or its link may have changed. If you used a Shortcut, check its name matches exactly.")
        }
    }
}
