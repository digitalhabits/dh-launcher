import SwiftUI
import LauncherCore

/// Reorder items and choose which appear in the widget, with the cut-off for
/// each widget size marked using the same numbers the widget uses.
struct HomeScreenListView: View {
    @Environment(LauncherModel.self) private var model

    var body: some View {
        let settings = model.settings
        let medium = WidgetCapacity.maxItems(for: .medium, textSize: settings.textSize, showDate: settings.showDate)
        let large = WidgetCapacity.maxItems(for: .large, textSize: settings.textSize, showDate: settings.showDate)
        let positions = homePositions()

        List {
            Section {
                ForEach(model.items) { item in
                    HStack {
                        Button {
                            model.toggleHomeScreen(id: item.id)
                        } label: {
                            Image(systemName: item.onHomeScreen ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.onHomeScreen ? Color.accentColor : .secondary)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(item.onHomeScreen ? "On home screen" : "Not on home screen")
                        Text(item.name)
                        Spacer()
                        if let pos = positions[item.id] {
                            Text(fitLabel(pos, medium: medium, large: large))
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
                .onMove { model.move(fromOffsets: $0, toOffset: $1) }
            } footer: {
                Text("Drag to reorder. Ticked apps appear in the widget, top to bottom. With your current text size\(settings.showDate ? " and the date shown" : ""), a medium widget fits \(medium) and a large widget fits \(large); the small widget shows the first one only.")
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Home screen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { DoneButton() }
    }

    /// 1-based position among the items shown in the widget.
    private func homePositions() -> [UUID: Int] {
        var result: [UUID: Int] = [:]
        var n = 0
        for item in model.items where item.onHomeScreen {
            n += 1
            result[item.id] = n
        }
        return result
    }

    private func fitLabel(_ pos: Int, medium: Int, large: Int) -> String {
        if pos == 1 { return "all sizes" }
        if pos <= medium { return "medium, large" }
        if pos <= large { return "large only" }
        return "doesn't fit"
    }
}
