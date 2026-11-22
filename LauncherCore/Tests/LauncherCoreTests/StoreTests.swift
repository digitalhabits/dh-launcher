import Foundation
import Testing
@testable import LauncherCore

struct StoreTests {
    let dir: URL
    let store: LauncherStore

    init() {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("LauncherStoreTests-\(UUID().uuidString)")
        store = LauncherStore(directory: dir)
    }

    @Test func missingFilesReturnDefaults() {
        #expect(store.loadItems().isEmpty)
        #expect(store.loadSettings() == .default)
    }

    @Test func defaultsAreCentredWithoutDate() throws {
        #expect(LauncherSettings.default.showDate == false)
        #expect(LauncherSettings.default.alignment == .center)
        #expect(LauncherSettings.default.lowercaseNames == true)
        // A settings file without the key (older or hand-written) also gets the default.
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data(#"{"theme":"black"}"#.utf8).write(to: dir.appendingPathComponent(LauncherStore.settingsFile))
        #expect(store.loadSettings().showDate == false)
    }

    @Test func itemsRoundTripPreservingOrderAndAllTargetKinds() {
        let items = [
            LauncherItem(name: "Maps", target: .urlScheme("maps://")),
            LauncherItem(name: "Spotify", target: .shortcut(name: "Open Spotify"), onHomeScreen: false),
            LauncherItem(name: "Docs", target: .web(URL(string: "https://example.com/a?b=c")!)),
        ]
        #expect(store.saveItems(items))
        #expect(store.loadItems() == items)
        #expect(store.item(id: items[1].id) == items[1])
        #expect(store.item(id: UUID()) == nil)
    }

    @Test func settingsRoundTrip() {
        let s = LauncherSettings(alignment: .trailing, textSize: .large, showDate: true, theme: .white, autoLaunchSingleMatch: false)
        #expect(store.saveSettings(s))
        #expect(store.loadSettings() == s)
    }

    @Test func corruptFilesReturnDefaults() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data("{not json".utf8).write(to: dir.appendingPathComponent(LauncherStore.itemsFile))
        try Data([0xFF, 0x00, 0x13]).write(to: dir.appendingPathComponent(LauncherStore.settingsFile))
        #expect(store.loadItems().isEmpty)
        #expect(store.loadSettings() == .default)
    }

    @Test func wrongShapeReturnsDefaults() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data(#"{"items": 3}"#.utf8).write(to: dir.appendingPathComponent(LauncherStore.itemsFile))
        #expect(store.loadItems().isEmpty)
    }

    @Test func partialSettingsFillDefaults() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data(#"{"theme":"white","textSize":"bogus"}"#.utf8).write(to: dir.appendingPathComponent(LauncherStore.settingsFile))
        let s = store.loadSettings()
        #expect(s.theme == .white)
        #expect(s.textSize == LauncherSettings.default.textSize)
        #expect(s.autoLaunchSingleMatch == true)
    }

    @Test func hasSavedItemsDistinguishesEmptyFromNeverSaved() {
        #expect(!store.hasSavedItems)
        #expect(store.saveItems([]))
        #expect(store.hasSavedItems)
        #expect(store.loadItems().isEmpty)
    }

    @Test func saveCreatesDirectory() {
        let nested = LauncherStore(directory: dir.appendingPathComponent("a/b"))
        #expect(nested.saveItems([LauncherItem(name: "x", target: .urlScheme("x://"))]))
        #expect(nested.loadItems().count == 1)
    }
}

struct DisplayNameTests {
    @Test func lowercasesOnlyWhenAsked() {
        var s = LauncherSettings()
        #expect(s.displayName("Messages") == "messages")
        #expect(s.displayName("İstanbul Maps", locale: Locale(identifier: "tr_TR")) == "istanbul maps")
        s.lowercaseNames = false
        #expect(s.displayName("Messages") == "Messages")
    }
}
