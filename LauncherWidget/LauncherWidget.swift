import WidgetKit
import SwiftUI
import LauncherCore

// MARK: Timeline

struct LauncherEntry: TimelineEntry {
    let date: Date
    let items: [LauncherItem]
    let settings: LauncherSettings
}

struct LauncherProvider: TimelineProvider {
    func placeholder(in context: Context) -> LauncherEntry {
        LauncherEntry(date: .now, items: Self.sampleItems, settings: .default)
    }

    func getSnapshot(in context: Context, completion: @escaping (LauncherEntry) -> Void) {
        let entry = currentEntry()
        // In the widget gallery, show something representative rather than an empty widget.
        if context.isPreview && entry.items.isEmpty {
            completion(LauncherEntry(date: .now, items: Self.sampleItems, settings: entry.settings))
        } else {
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LauncherEntry>) -> Void) {
        let entry = currentEntry()
        // One entry. If the date is shown, refresh just after midnight; other
        // changes arrive via WidgetCenter.reloadAllTimelines() from the app.
        let policy: TimelineReloadPolicy
        if entry.settings.showDate,
           let midnight = Calendar.current.nextDate(after: entry.date, matching: DateComponents(hour: 0, minute: 0, second: 5), matchingPolicy: .nextTime) {
            policy = .after(midnight)
        } else {
            policy = .never
        }
        completion(Timeline(entries: [entry], policy: policy))
    }

    private func currentEntry() -> LauncherEntry {
        let store = LauncherStore.shared()
        return LauncherEntry(date: .now, items: store.loadItems(), settings: store.loadSettings())
    }

    static let sampleItems: [LauncherItem] = ["Phone", "Messages", "Maps", "Calendar", "Notes", "Music", "Camera", "Settings"]
        .map { LauncherItem(name: $0, target: .urlScheme("x://")) }
}

// MARK: Views

struct LauncherWidgetView: View {
    let entry: LauncherEntry
    @Environment(\.widgetFamily) private var family

    private var settings: LauncherSettings { entry.settings }
    private var size: WidgetSize {
        switch family {
        case .systemSmall: .small
        case .systemMedium: .medium
        default: .large
        }
    }
    private var visible: [LauncherItem] {
        WidgetCapacity.visibleItems(entry.items, size: size, settings: settings)
    }
    private var foreground: Color { settings.theme == .black ? .white : .black }
    private var secondary: Color { settings.theme == .black ? Color(white: 0.6) : Color(white: 0.4) }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: frameAlignment)
            .padding(.horizontal, 18)
            .padding(.vertical, family == .systemSmall ? 16 : 14)
            .containerBackground(settings.theme == .black ? Color.black : Color.white, for: .widget)
    }

    @ViewBuilder private var content: some View {
        if visible.isEmpty {
            emptyState
                .widgetURL(LaunchRouter.appURL)
        } else if family == .systemSmall {
            VStack(alignment: horizontal, spacing: 8) {
                dateLine
                row(visible[0])
            }
            .widgetURL(LaunchRouter.widgetURL(for: visible[0]))
        } else {
            VStack(alignment: horizontal, spacing: rowSpacing) {
                dateLine
                ForEach(visible) { item in
                    Link(destination: LaunchRouter.widgetURL(for: item)) { row(item) }
                }
            }
        }
    }

    @ViewBuilder private var dateLine: some View {
        if settings.showDate {
            Text(entry.date, format: family == .systemSmall
                 ? .dateTime.weekday(.abbreviated).day().month(.abbreviated)
                 : .dateTime.weekday(.wide).day().month(.wide))
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(secondary)
                .widgetAccentable(false)
                .padding(.bottom, 2)
        }
    }

    private func row(_ item: LauncherItem) -> some View {
        Text(item.name)
            .font(.system(size: fontSize, weight: .light))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .widgetAccentable()
            .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    private var emptyState: some View {
        Text("Open \(Bundle.main.displayName) to add apps")
            .font(.system(size: 17, weight: .light))
            .foregroundStyle(foreground)
            .multilineTextAlignment(textAlignment)
            .widgetAccentable()
    }

    // MARK: Metrics (kept in step with WidgetCapacity in LauncherCore)

    private var fontSize: CGFloat {
        switch settings.textSize {
        case .small: 17
        case .medium: 22
        case .large: 27
        }
    }

    /// Spacing chosen so WidgetCapacity's row counts fit each family with room
    /// to spare (large is roughly twice the height of medium).
    private var rowSpacing: CGFloat {
        switch (family, settings.textSize) {
        case (.systemLarge, .small): 9
        case (.systemLarge, .medium): 14
        case (.systemLarge, .large): 14
        case (_, .small): 6
        case (_, .medium): 8
        case (_, .large): 9
        }
    }

    private var horizontal: HorizontalAlignment {
        switch settings.alignment { case .leading: .leading; case .center: .center; case .trailing: .trailing }
    }
    /// The list is always centred vertically in the widget; the setting only
    /// controls the horizontal position.
    private var frameAlignment: Alignment {
        switch settings.alignment { case .leading: .leading; case .center: .center; case .trailing: .trailing }
    }
    private var textAlignment: TextAlignment {
        switch settings.alignment { case .leading: .leading; case .center: .center; case .trailing: .trailing }
    }
}

extension Bundle {
    var displayName: String {
        (object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "the launcher"
    }
}

// MARK: Widget

@main
struct LauncherWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LauncherWidget", provider: LauncherProvider()) { entry in
            LauncherWidgetView(entry: entry)
        }
        .configurationDisplayName(Bundle.main.displayName)
        .description("Your apps as a plain text list. Tap a name to open it.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemLarge) {
    LauncherWidget()
} timeline: {
    LauncherEntry(date: .now, items: LauncherProvider.sampleItems, settings: .default)
}
