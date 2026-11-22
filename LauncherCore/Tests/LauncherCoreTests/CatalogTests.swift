import Foundation
import Testing
@testable import LauncherCore

struct CatalogTests {
    @Test func decodesValidJSON() throws {
        let json = #"[{"name":"Spotify","scheme":"spotify://","verified":false},{"name":"Maps","scheme":"maps://","verified":true}]"#
        let entries = try AppCatalog.decode(Data(json.utf8))
        #expect(entries == [CatalogEntry(name: "Spotify", scheme: "spotify://"), CatalogEntry(name: "Maps", scheme: "maps://", verified: true)])
    }

    @Test func rejectsInvalidJSON() {
        #expect(throws: (any Error).self) { try AppCatalog.decode(Data(#"[{"name":"x"}]"#.utf8)) }
    }

    @Test func bundledCatalogIsWellFormed() {
        let entries = AppCatalog.bundled()
        #expect(entries.count >= 40)
        // Unique names, every scheme forms a valid destination, sorted.
        #expect(Set(entries.map(\.name)).count == entries.count)
        for e in entries {
            #expect(LaunchRouter.destination(for: .urlScheme(e.scheme)) != nil, "bad scheme for \(e.name)")
        }
        #expect(entries.map(\.name) == entries.map(\.name).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending })
    }

    @Test func searchPrefersPrefixMatches() {
        let entries = [CatalogEntry(name: "Google Maps", scheme: "comgooglemaps://"), CatalogEntry(name: "Maps", scheme: "maps://"), CatalogEntry(name: "Music", scheme: "music://")]
        #expect(AppCatalog.search(entries, query: "maps").map(\.name) == ["Maps", "Google Maps"])
        #expect(AppCatalog.search(entries, query: "").count == 3)
        #expect(AppCatalog.search(entries, query: "MU").map(\.name) == ["Music"])
    }

    @Test func searchIgnoresDiacritics() {
        #expect(Search.filter(["Café"], query: "cafe", name: { $0 }) == ["Café"])
    }
}
