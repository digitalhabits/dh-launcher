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
    /// Large and iPad's extra-large (twice as wide, same height) hold the same rows.
    private var isLarge: Bool { family == .systemLarge || family == .systemExtraLarge }
    private var foreground: Color { settings.theme == .black ? .white : .black }

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
                dateLine(fontSize: fontSize)
                row(visible[0], fontSize: fontSize)
            }
            .widgetURL(LaunchRouter.widgetURL(for: visible[0]))
        } else if family == .systemExtraLarge {
            // iPad's extra-large is twice as wide as large but no taller, so the
            // names grow to fill the height: a short list gets very large type.
            GeometryReader { geo in
                let size = extraLargeFontSize(height: geo.size.height)
                list(fontSize: size, spacing: size * 0.4)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: frameAlignment)
            }
        } else {
            list(fontSize: fontSize, spacing: rowSpacing)
        }
    }

    private func list(fontSize: CGFloat, spacing: CGFloat) -> some View {
        VStack(alignment: horizontal, spacing: spacing) {
            dateLine(fontSize: fontSize)
            ForEach(visible) { item in
                Link(destination: LaunchRouter.widgetURL(for: item)) { row(item, fontSize: fontSize) }
            }
        }
    }

    /// The largest size at which every row fits the height (a row is about
    /// 1.6 × the font size with its spacing), between the chosen text size and
    /// 1.8 × that.
    private func extraLargeFontSize(height: CGFloat) -> CGFloat {
        let rows = CGFloat(visible.count) + (settings.showDate ? 1.2 : 0)
        let fitting = height / (max(rows, 1) * 1.6)
        return min(fontSize * 1.8, max(fontSize, fitting))
    }

    @ViewBuilder private func dateLine(fontSize: CGFloat) -> some View {
        if settings.showDate {
            Text(entry.date, format: family == .systemSmall
                 ? .dateTime.weekday(.abbreviated).day().month(.abbreviated)
                 : .dateTime.weekday(.wide).day().month(.wide))
                .font(Typography.font(settings.fontStyle, size: family == .systemSmall ? 14 : fontSize * 0.7, weight: .medium))
                .foregroundStyle(foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .widgetAccentable()
                .padding(.bottom, isLarge ? 10 : 4)
        }
    }

    private func row(_ item: LauncherItem, fontSize: CGFloat) -> some View {
        Text(settings.displayName(item.name))
            .font(Typography.font(settings.fontStyle, size: fontSize, weight: nameWeight))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .widgetAccentable()
            .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    private var emptyState: some View {
        Text("Open \(Bundle.main.displayName) to add apps")
            .font(Typography.font(settings.fontStyle, size: 17, weight: nameWeight))
            .foregroundStyle(foreground)
            .multilineTextAlignment(textAlignment)
            .widgetAccentable()
    }

    // MARK: Metrics (kept in step with WidgetCapacity in LauncherCore)

    private var fontSize: CGFloat {
        switch settings.textSize {
        case .small: 18
        case .medium: 26
        case .large: 29
        }
    }

    /// Light in the system font; the brand font's lightest weight is Regular.
    private var nameWeight: Font.Weight { settings.fontStyle == .system ? .light : .regular }


    /// Spacing chosen so WidgetCapacity's row counts fit each family with room
    /// to spare (large is roughly twice the height of medium).
    private var rowSpacing: CGFloat {
        switch (isLarge, settings.textSize) {
        case (true, .small): 8
        case (true, .medium): 10
        case (true, .large): 13
        case (false, .small): 5
        case (false, .medium): 4
        case (false, .large): 7
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemLarge) {
    LauncherWidget()
} timeline: {
    LauncherEntry(date: .now, items: LauncherProvider.sampleItems, settings: .default)
}
