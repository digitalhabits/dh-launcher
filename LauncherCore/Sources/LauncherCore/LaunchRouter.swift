import Foundation

/// Builds and parses the URLs that connect widget, host app and target apps.
public enum LaunchRouter {
    public static let scheme = "dhlauncher"
    static let openHost = "open"

    /// The URL a widget row links to: `dhlauncher://open?id=<uuid>`.
    public static func widgetURL(for item: LauncherItem) -> URL {
        widgetURL(forID: item.id)
    }

    public static func widgetURL(forID id: UUID) -> URL {
        var c = URLComponents()
        c.scheme = scheme
        c.host = openHost
        c.queryItems = [URLQueryItem(name: "id", value: id.uuidString)]
        return c.url!
    }

    /// URL the widget opens when there is nothing to launch (empty state, small widget with no items).
    public static let appURL = URL(string: "\(scheme)://home")!

    /// Inverse of `widgetURL(for:)`. Returns nil for anything else.
    public static func parse(_ url: URL) -> UUID? {
        guard let c = URLComponents(url: url, resolvingAgainstBaseURL: false),
              c.scheme?.lowercased() == scheme,
              c.host?.lowercased() == openHost,
              let value = c.queryItems?.first(where: { $0.name == "id" })?.value
        else { return nil }
        return UUID(uuidString: value)
    }

    /// Characters allowed unescaped in a query value. Stricter than
    /// `.urlQueryAllowed`, which leaves `&`, `=`, `+` and `?` unescaped and
    /// would break or alter shortcut names containing them.
    static let queryValueAllowed: CharacterSet = {
        var set = CharacterSet.alphanumerics.intersection(CharacterSet(charactersIn: Unicode.Scalar(0)..<Unicode.Scalar(128)))
        set.insert(charactersIn: "-._~")
        return set
    }()

    /// The real URL to open for a target, or nil if it cannot form a valid URL.
    public static func destination(for target: LaunchTarget) -> URL? {
        switch target {
        case .urlScheme(let raw):
            return schemeURL(raw)
        case .shortcut(let name):
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty,
                  let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: queryValueAllowed)
            else { return nil }
            return URL(string: "shortcuts://run-shortcut?name=\(encoded)")
        case .web(let url):
            guard let s = url.scheme?.lowercased(), s == "https" || s == "http" else { return nil }
            return url
        }
    }

    /// Accepts "spotify://", "spotify:", "spotify" or a full URL like "maps://?q=x".
    static func schemeURL(_ raw: String) -> URL? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        let full: String
        if s.contains(":") {
            full = s
        } else {
            full = s + "://"
        }
        guard let url = URL(string: full), let scheme = url.scheme, isValidScheme(scheme) else { return nil }
        return url
    }

    static func isValidScheme(_ s: String) -> Bool {
        guard let first = s.unicodeScalars.first, CharacterSet.letters.contains(first), first.isASCII else { return false }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+-.")
        return s.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    /// The shortcut name the app proposes for an app: "Open <App>".
    public static func suggestedShortcutName(forApp app: String) -> String {
        "Open \(app.trimmingCharacters(in: .whitespacesAndNewlines))"
    }

    /// Parses what a user typed into the "custom" form: an https link becomes
    /// `.web`, anything else with a valid scheme becomes `.urlScheme`.
    public static func target(fromUserInput input: String) -> LaunchTarget? {
        let s = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        if let url = URL(string: s), let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http" {
            return url.host == nil ? nil : .web(url)
        }
        return schemeURL(s) == nil ? nil : .urlScheme(s)
    }
}
