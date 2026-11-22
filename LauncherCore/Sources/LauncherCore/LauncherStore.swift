import Foundation

/// Loads and saves the item list and settings as JSON files in a directory
/// (the App Group container in the app; a temp directory in tests).
/// Missing or corrupt files yield defaults; nothing here throws or crashes.
public struct LauncherStore: Sendable {
    public let directory: URL

    static let itemsFile = "items.json"
    static let settingsFile = "settings.json"

    public init(directory: URL) {
        self.directory = directory
    }

    /// Store backed by the shared App Group container. The group identifier is
    /// read from the `AppGroupIdentifier` Info.plist key (set from project.yml),
    /// so changing the bundle prefix needs no code change. Falls back to the
    /// app's Application Support directory if the container is unavailable.
    public static func shared(bundle: Bundle = .main) -> LauncherStore {
        let fm = FileManager.default
        if let group = bundle.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String,
           let url = fm.containerURL(forSecurityApplicationGroupIdentifier: group) {
            return LauncherStore(directory: url)
        }
        let fallback = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return LauncherStore(directory: fallback)
    }

    // MARK: Items

    public func loadItems() -> [LauncherItem] {
        LauncherItem.normalised(load([LauncherItem].self, from: Self.itemsFile) ?? [])
    }

    @discardableResult
    public func saveItems(_ items: [LauncherItem]) -> Bool {
        save(items, to: Self.itemsFile)
    }

    /// Whether an items file exists at all (distinguishes "never set up" from "emptied by the user").
    public var hasSavedItems: Bool {
        FileManager.default.fileExists(atPath: directory.appendingPathComponent(Self.itemsFile).path)
    }

    public func item(id: UUID) -> LauncherItem? {
        loadItems().first { $0.id == id }
    }

    // MARK: Settings

    public func loadSettings() -> LauncherSettings {
        load(LauncherSettings.self, from: Self.settingsFile) ?? .default
    }

    @discardableResult
    public func saveSettings(_ settings: LauncherSettings) -> Bool {
        save(settings, to: Self.settingsFile)
    }

    // MARK: Plumbing

    private func load<T: Decodable>(_ type: T.Type, from file: String) -> T? {
        let url = directory.appendingPathComponent(file)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<T: Encodable>(_ value: T, to file: String) -> Bool {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(value)
            try data.write(to: directory.appendingPathComponent(file), options: .atomic)
            return true
        } catch {
            return false
        }
    }
}
