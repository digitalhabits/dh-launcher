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

    @Test func visibleItemsFiltersAndTruncates() {
        let items = (0..<12).map { LauncherItem(name: "\($0)", target: .urlScheme("x://"), onHomeScreen: $0 != 1) }
        let s = LauncherSettings(textSize: .medium, showDate: false)
        let medium = WidgetCapacity.visibleItems(items, size: .medium, settings: s)
        #expect(medium.map(\.name) == ["0", "2", "3", "4"])
        #expect(WidgetCapacity.visibleItems(items, size: .small, settings: s).map(\.name) == ["0"])
    }
}
