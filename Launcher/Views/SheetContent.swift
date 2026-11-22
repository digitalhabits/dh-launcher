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
            case .homeScreen:
                HomeScreenListView()
            case .settings:
                SettingsView()
            case .setupGuide:
                SetupGuideView()
            case .shortcutGuide(let appName):
                ShortcutGuideView(appName: appName, onSave: nil)
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
            Text("iOS refused the link. For a URL scheme, the app may not be installed or may use a different scheme. For a Shortcut, check the name matches exactly.")
        }
    }
}
