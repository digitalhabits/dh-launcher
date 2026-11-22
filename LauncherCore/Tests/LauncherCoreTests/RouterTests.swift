import Foundation
import Testing
@testable import LauncherCore

struct RouterTests {
    @Test func widgetURLRoundTrip() {
        let item = LauncherItem(name: "Maps", target: .urlScheme("maps://"))
        let url = LaunchRouter.widgetURL(for: item)
        #expect(url.absoluteString == "dhlauncher://open?id=\(item.id.uuidString)")
        #expect(LaunchRouter.parse(url) == item.id)
    }

    @Test(arguments: [
        "dhlauncher://open",
        "dhlauncher://open?id=not-a-uuid",
        "dhlauncher://home",
        "other://open?id=6F1C2E2A-7E7B-4B8B-9D3C-1E2F3A4B5C6D",
        "https://open?id=6F1C2E2A-7E7B-4B8B-9D3C-1E2F3A4B5C6D",
    ])
    func parseRejects(_ s: String) {
        #expect(LaunchRouter.parse(URL(string: s)!) == nil)
    }

    @Test func parseIsCaseInsensitiveOnSchemeAndHost() {
        let id = UUID()
        #expect(LaunchRouter.parse(URL(string: "DHLauncher://OPEN?id=\(id.uuidString.lowercased())")!) == id)
    }

    @Test(arguments: [
        ("Open Maps", "shortcuts://run-shortcut?name=Open%20Maps"),
        ("Tom & Jerry", "shortcuts://run-shortcut?name=Tom%20%26%20Jerry"),
        ("a=b+c?d#e/f", "shortcuts://run-shortcut?name=a%3Db%2Bc%3Fd%23e%2Ff"),
        ("Open 🎵", "shortcuts://run-shortcut?name=Open%20%F0%9F%8E%B5"),
        ("打开 微信", "shortcuts://run-shortcut?name=%E6%89%93%E5%BC%80%20%E5%BE%AE%E4%BF%A1"),
        ("Café", "shortcuts://run-shortcut?name=Caf%C3%A9"),
        ("  Open Notes  ", "shortcuts://run-shortcut?name=Open%20Notes"),
    ])
    func shortcutEncoding(name: String, expected: String) throws {
        let url = try #require(LaunchRouter.destination(for: .shortcut(name: name)))
        #expect(url.absoluteString == expected)
        // Decoding the query gives back the trimmed name exactly.
        let comps = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(comps.queryItems?.first?.value == name.trimmingCharacters(in: .whitespaces))
    }

    @Test func emptyShortcutNameHasNoDestination() {
        #expect(LaunchRouter.destination(for: .shortcut(name: "   ")) == nil)
    }

    @Test(arguments: [
        ("maps://", "maps://"),
        ("spotify", "spotify://"),
        ("sms:", "sms:"),
        ("maps://?q=coffee", "maps://?q=coffee"),
        (" x-apple-reminderkit:// ", "x-apple-reminderkit://"),
    ])
    func schemeDestinations(raw: String, expected: String) {
        #expect(LaunchRouter.destination(for: .urlScheme(raw))?.absoluteString == expected)
    }

    @Test(arguments: ["", "1password://", "has space://", "://", "é://"])
    func invalidSchemes(raw: String) {
        #expect(LaunchRouter.destination(for: .urlScheme(raw)) == nil)
    }

    @Test func webDestinations() {
        #expect(LaunchRouter.destination(for: .web(URL(string: "https://example.com")!))?.absoluteString == "https://example.com")
        #expect(LaunchRouter.destination(for: .web(URL(string: "ftp://example.com")!)) == nil)
    }

    @Test func userInputParsing() {
        #expect(LaunchRouter.target(fromUserInput: "https://example.com/x") == .web(URL(string: "https://example.com/x")!))
        #expect(LaunchRouter.target(fromUserInput: "spotify://") == .urlScheme("spotify://"))
        #expect(LaunchRouter.target(fromUserInput: "spotify") == .urlScheme("spotify"))
        #expect(LaunchRouter.target(fromUserInput: "https://") == nil)
        #expect(LaunchRouter.target(fromUserInput: "not a scheme") == nil)
        #expect(LaunchRouter.target(fromUserInput: "") == nil)
    }

    @Test func suggestedShortcutName() {
        #expect(LaunchRouter.suggestedShortcutName(forApp: " Spotify ") == "Open Spotify")
    }
}
