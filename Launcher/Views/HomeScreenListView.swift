import SwiftUI
import LauncherCore

/// Reorder the widget's apps, with each widget size's cut-off marked using
/// the same numbers the widget uses.
struct HomeScreenListView: View {
    @Environment(LauncherModel.self) private var model

    var body: some View {
        let settings = model.settings
        let medium = WidgetCapacity.maxItems(for: .medium, textSize: settings.textSize, showDate: settings.showDate)
        let large = WidgetCapacity.maxItems(for: .large, textSize: settings.textSize, showDate: settings.showDate)

        List {
            Section {
                ForEach(Array(model.items.enumerated()), id: \.element.id) { index, item in
                    HStack {
                        Text(settings.displayName(item.name))
                            .foregroundStyle(index < large ? .primary : .secondary)
                        Spacer()
                        Text(fitLabel(index + 1, medium: medium, large: large))
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .onMove { model.move(fromOffsets: $0, toOffset: $1) }
            } footer: {
                Text("Drag to reorder. The widget shows your apps top to bottom. With your current text size\(settings.showDate ? " and the date shown" : ""), a medium widget fits \(medium) and a large widget fits \(large); the small widget shows the first one only.")
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Home screen layout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { DoneButton() }
    }

    private func fitLabel(_ pos: Int, medium: Int, large: Int) -> String {
        if pos == 1 { return "all sizes" }
        if pos <= medium { return "medium, large" }
        if pos <= large { return "large only" }
        return "doesn't fit"
    }
}
