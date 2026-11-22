import Foundation

/// One entry in the launcher: a name and how to open it.
public struct LauncherItem: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    /// Text shown in the widget and the drawer.
    public var name: String
    public var target: LaunchTarget
    /// Shown in the widget (true) or drawer-only (false).
    public var onHomeScreen: Bool

    public init(id: UUID = UUID(), name: String, target: LaunchTarget, onHomeScreen: Bool = true) {
        self.id = id
        self.name = name
        self.target = target
        self.onHomeScreen = onHomeScreen
    }
}

public enum LaunchTarget: Codable, Hashable, Sendable {
    /// A custom URL scheme such as "spotify://".
    case urlScheme(String)
    /// The name of a Shortcut, run via shortcuts://run-shortcut?name=...
    case shortcut(name: String)
    /// An https link; opens in the browser or via a universal link.
    case web(URL)
}

public struct LauncherSettings: Codable, Hashable, Sendable {
    public enum Alignment: String, Codable, CaseIterable, Sendable { case leading, center, trailing }
    public enum TextSize: String, Codable, CaseIterable, Sendable { case small, medium, large }
    public enum Theme: String, Codable, CaseIterable, Sendable { case black, white }

    public var alignment: Alignment
    public var textSize: TextSize
    public var showDate: Bool
    public var theme: Theme
    /// Launch automatically when a drawer search leaves exactly one match.
    public var autoLaunchSingleMatch: Bool

    public init(alignment: Alignment = .leading,
                textSize: TextSize = .medium,
                showDate: Bool = true,
                theme: Theme = .black,
                autoLaunchSingleMatch: Bool = true) {
        self.alignment = alignment
        self.textSize = textSize
        self.showDate = showDate
        self.theme = theme
        self.autoLaunchSingleMatch = autoLaunchSingleMatch
    }

    public static let `default` = LauncherSettings()

    // Decode field by field so settings files written by older versions
    // (missing keys) still load, with defaults for whatever is absent.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = LauncherSettings.default
        alignment = (try? c.decodeIfPresent(Alignment.self, forKey: .alignment)) ?? d.alignment
        textSize = (try? c.decodeIfPresent(TextSize.self, forKey: .textSize)) ?? d.textSize
        showDate = (try? c.decodeIfPresent(Bool.self, forKey: .showDate)) ?? d.showDate
        theme = (try? c.decodeIfPresent(Theme.self, forKey: .theme)) ?? d.theme
        autoLaunchSingleMatch = (try? c.decodeIfPresent(Bool.self, forKey: .autoLaunchSingleMatch)) ?? d.autoLaunchSingleMatch
    }
}

/// Widget families, mirrored here so capacity can be tested without WidgetKit.
public enum WidgetSize: String, CaseIterable, Sendable {
    case small, medium, large
}

/// How many items fit in a widget. The single source of truth for both the
/// widget and the app's home-screen list.
public enum WidgetCapacity {
    public static func maxItems(for size: WidgetSize, textSize: LauncherSettings.TextSize, showDate: Bool) -> Int {
        let base: Int
        switch (size, textSize) {
        case (.small, _): return 1
        case (.medium, .small): base = 5
        case (.medium, .medium): base = 4
        case (.medium, .large): base = 3
        case (.large, .small): base = 11
        case (.large, .medium): base = 8
        case (.large, .large): base = 7
        }
        return showDate ? max(1, base - 1) : base
    }

    /// The items the widget shows, in order, truncated to capacity.
    public static func visibleItems(_ items: [LauncherItem], size: WidgetSize, settings: LauncherSettings) -> [LauncherItem] {
        let max = maxItems(for: size, textSize: settings.textSize, showDate: settings.showDate)
        return Array(items.filter(\.onHomeScreen).prefix(max))
    }
}
