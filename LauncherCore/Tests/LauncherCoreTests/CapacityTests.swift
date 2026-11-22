import Foundation
import Testing
@testable import LauncherCore

struct CapacityTests {
    @Test func plannedDefaults() {
        #expect(WidgetCapacity.maxItems(for: .medium, textSize: .medium, showDate: false) == 4)
        #expect(WidgetCapacity.maxItems(for: .large, textSize: .medium, showDate: false) == 8)
        #expect(WidgetCapacity.maxItems(for: .small, textSize: .large, showDate: true) == 1)
    }

    @Test func dateCostsOneRow() {
        for size in [WidgetSize.medium, .large] {
            for t in LauncherSettings.TextSize.allCases {
                #expect(WidgetCapacity.maxItems(for: size, textSize: t, showDate: true) == WidgetCapacity.maxItems(for: size, textSize: t, showDate: false) - 1)
            }
        }
    }

    @Test func visibleItemsTruncatesInOrder() {
        let items = (0..<12).map { LauncherItem(name: "\($0)", target: .urlScheme("x://")) }
        let s = LauncherSettings(textSize: .medium, showDate: false)
        #expect(WidgetCapacity.visibleItems(items, size: .medium, settings: s).map(\.name) == ["0", "1", "2", "3"])
        #expect(WidgetCapacity.visibleItems(items, size: .small, settings: s).map(\.name) == ["0"])
        #expect(WidgetCapacity.fits(position: 3, size: .medium, settings: s))
        #expect(!WidgetCapacity.fits(position: 4, size: .medium, settings: s))
    }
}

struct SlotsLeftTests {
    @Test func countsAllItems() {
        let s = LauncherSettings(textSize: .medium, showDate: false)
        let items = (0..<3).map { LauncherItem(name: "\($0)", target: .urlScheme("x://")) }
        #expect(WidgetCapacity.slotsLeft(items, size: .large, settings: s) == 5)
        #expect(WidgetCapacity.slotsLeft(items, size: .medium, settings: s) == 1)
        #expect(WidgetCapacity.slotsLeft(items, size: .small, settings: s) == 0)
    }
}

struct NormalisedTests {
    @Test func offWidgetItemsMoveToTheEndAndCountAsOn() {
        let a = LauncherItem(name: "a", target: .urlScheme("x://"))
        let b = LauncherItem(name: "b", target: .urlScheme("x://"), onHomeScreen: false)
        let c = LauncherItem(name: "c", target: .urlScheme("x://"))
        let d = LauncherItem(name: "d", target: .urlScheme("x://"), onHomeScreen: false)
        let result = LauncherItem.normalised([a, b, c, d])
        #expect(result.map(\.name) == ["a", "c", "b", "d"])
        #expect(result.allSatisfy { $0.onHomeScreen })
    }

    @Test func storeNormalisesOnLoad() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("norm-\(UUID().uuidString)")
        let store = LauncherStore(directory: dir)
        store.saveItems([LauncherItem(name: "off", target: .urlScheme("x://"), onHomeScreen: false),
                         LauncherItem(name: "on", target: .urlScheme("x://"))])
        #expect(store.loadItems().map(\.name) == ["on", "off"])
    }
}
