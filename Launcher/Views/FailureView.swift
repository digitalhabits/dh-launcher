import SwiftUI
import LauncherCore

/// Shown when iOS refuses to open an item's target.
struct FailureView: View {
    let item: LauncherItem
    @Environment(LauncherModel.self) private var model
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Spacer()
            Text("Couldn't open \(item.name)")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(palette.foreground)
            Text(explanation)
                .font(.callout)
                .foregroundStyle(palette.secondary)
            VStack(alignment: .leading, spacing: 16) {
                link("edit \(item.name)") { model.recover(showing: .edit(item.id)) }
                link("set it up with a Shortcut") { model.recover(showing: .shortcutGuide(appName: item.name)) }
                link("back") { model.showDrawer() }
            }
            .padding(.top, 8)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var explanation: String {
        switch item.target {
        case .urlScheme(let s): "Nothing on this iPhone answers to \(s). The app may not be installed, or it uses a different URL scheme. A Shortcut works for any app."
        case .shortcut(let n): "iOS couldn't run the Shortcut \"\(n)\"."
        case .web(let u): "iOS couldn't open \(u.absoluteString)."
        }
    }

    private func link(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(size: 20, weight: .light))
            .foregroundStyle(palette.foreground)
    }
}
