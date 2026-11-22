import SwiftUI
import UIKit
import WidgetKit
import LauncherCore

/// App-wide state: the item list, settings, and what the root screen shows.
/// Every mutation saves to the shared store and reloads the widget.
@MainActor
@Observable
final class LauncherModel {
    enum Phase: Equatable {
        /// Normal UI: the drawer and its sheets.
        case drawer
        /// Handing off to another app: plain black screen only.
        case forwarding
        /// The target refused to open.
        case failed(LauncherItem)
    }

    private(set) var items: [LauncherItem]
    private(set) var settings: LauncherSettings
    var phase: Phase = .drawer
    /// The sheet shown over the drawer, if any.
    var sheet: Sheet?
    /// Incremented whenever the drawer should reset (clear search, refocus).
    private(set) var drawerResetToken = 0

    private let store: LauncherStore

    init(store: LauncherStore = .shared()) {
        self.store = store
        self.items = store.loadItems()
        self.settings = store.loadSettings()
        if !store.hasSavedItems {
            items = Self.starterItems
            persistItems()
        }
    }

    /// Apple apps present on every iPhone, so a fresh install is not empty.
    /// All five schemes were confirmed to open on the iOS 26.5 simulator.
    static var starterItems: [LauncherItem] {
        [
            LauncherItem(name: "Messages", target: .urlScheme("sms:")),
            LauncherItem(name: "Calendar", target: .urlScheme("calshow://")),
            LauncherItem(name: "Maps", target: .urlScheme("maps://")),
            LauncherItem(name: "Photos", target: .urlScheme("photos-redirect://")),
            LauncherItem(name: "Shortcuts", target: .urlScheme("shortcuts://")),
        ]
    }

    // MARK: Launching

    /// Entry point for every incoming URL (widget taps, simctl openurl).
    func handle(url: URL) {
        guard let id = LaunchRouter.parse(url) else {
            showDrawer()
            return
        }
        // Re-read from disk: the widget may have been tapped long after this
        // process loaded, and another process (none today) could have edited.
        reload()
        guard let item = items.first(where: { $0.id == id }) else {
            showDrawer()
            return
        }
        launch(item)
    }

    func launch(_ item: LauncherItem) {
        sheet = nil
        guard let destination = LaunchRouter.destination(for: item.target) else {
            phase = .failed(item)
            return
        }
        phase = .forwarding
        UIApplication.shared.open(destination, options: [:]) { [weak self] success in
            guard let self else { return }
            if success {
                self.scheduleForwardingFallback()
            } else {
                self.phase = .failed(item)
            }
        }
    }

    /// If the hand-off reported success but we are still frontmost after a
    /// moment (nothing visible opened), don't leave the user on a black screen.
    private func scheduleForwardingFallback() {
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard let self, self.phase == .forwarding,
                  UIApplication.shared.applicationState == .active else { return }
            self.showDrawer()
        }
    }

    /// Called when the scene goes to the background: whatever we were doing,
    /// the next time the user sees the app it should be the drawer.
    func didEnterBackground() {
        if phase == .forwarding { showDrawer() }
    }

    func showDrawer() {
        phase = .drawer
        drawerResetToken &+= 1
    }

    /// From the failure screen: back to the drawer with a sheet open.
    func recover(showing sheet: Sheet) {
        showDrawer()
        self.sheet = sheet
    }

    // MARK: Editing

    func reload() {
        items = store.loadItems()
        settings = store.loadSettings()
    }

    func add(_ item: LauncherItem) {
        items.append(item)
        persistItems()
    }

    func update(_ item: LauncherItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[i] = item
        persistItems()
    }

    func delete(id: UUID) {
        items.removeAll { $0.id == id }
        persistItems()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        persistItems()
    }

    func toggleHomeScreen(id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].onHomeScreen.toggle()
        persistItems()
    }

    func updateSettings(_ change: (inout LauncherSettings) -> Void) {
        change(&settings)
        store.saveSettings(settings)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func item(id: UUID) -> LauncherItem? {
        items.first { $0.id == id }
    }

    private func persistItems() {
        store.saveItems(items)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

/// Sheets presented over the drawer.
enum Sheet: Identifiable, Hashable {
    case add
    case edit(UUID)
    case homeScreen
    case settings
    case setupGuide
    case shortcutGuide(appName: String)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let id): "edit-\(id)"
        case .homeScreen: "home"
        case .settings: "settings"
        case .setupGuide: "setup"
        case .shortcutGuide(let name): "shortcut-\(name)"
        }
    }
}
