import Foundation

/// A known app and its URL scheme, from the bundled catalog.json.
public struct CatalogEntry: Codable, Hashable, Identifiable, Sendable {
    public var name: String
    public var scheme: String
    /// True only if someone confirmed the scheme opens the app on a simulator or device.
    public var verified: Bool

    public var id: String { name + "|" + scheme }

    public init(name: String, scheme: String, verified: Bool = false) {
        self.name = name
        self.scheme = scheme
        self.verified = verified
    }
}

public enum AppCatalog {
    public static func decode(_ data: Data) throws -> [CatalogEntry] {
        try JSONDecoder().decode([CatalogEntry].self, from: data)
    }

    /// Entries from the catalog.json bundled in this package, sorted by name.
    /// Returns an empty list if the resource is missing or invalid.
    public static func bundled() -> [CatalogEntry] {
        guard let url = Bundle.module.url(forResource: "catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? decode(data)
        else { return [] }
        return entries.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public static func search(_ entries: [CatalogEntry], query: String) -> [CatalogEntry] {
        Search.filter(entries, query: query, name: \.name)
    }
}

public enum Search {
    /// Case- and diacritic-insensitive substring filter, prefix matches first.
    public static func filter<T>(_ items: [T], query: String, name: (T) -> String) -> [T] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return items }
        let opts: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        let matches = items.filter { name($0).range(of: q, options: opts) != nil }
        let prefix = matches.filter { name($0).range(of: q, options: opts.union(.anchored)) != nil }
        let rest = matches.filter { name($0).range(of: q, options: opts.union(.anchored)) == nil }
        return prefix + rest
    }
}
