# Minimal text launcher for iOS — implementation plan

A free, open-source iOS app inspired by [Olauncher](https://github.com/tanujnotes/olauncher) (Android).
This is a fresh SwiftUI/WidgetKit app, not a port: no Olauncher code is reused.

Working title: **DH Launcher** (placeholder; do not use "Olauncher" in the app name).

## 1. What we are building

iOS does not allow replacing the home screen. The product is therefore:

1. **A home-screen widget** showing a plain text list of app names on a black background. Tapping a name launches that app.
2. **A host app** that doubles as the "app drawer": a searchable text list of every app the user has added, plus settings and setup guides.
3. **A setup guide** that walks the user through making the widget their whole home screen (black wallpaper, one page, widget on it).

### Platform constraints that shape the design (verified, do not try to work around)

- There is no public API to list installed apps. The user builds their own list.
- There is no public API to launch an app by bundle ID. Launching goes through either
  - a **URL scheme** (`spotify://`), where the app has one, or
  - a **Shortcut** containing the "Open App" action, run via `shortcuts://run-shortcut?name=<name>`. This works for any app.
- A widget cannot open another app directly. `Link` / `widgetURL` always open the **host app**, which must then forward to the target. A short bounce through the host app is unavoidable in v1.
- `OpenURLIntent` (iOS 18) only reliably opens universal links, not custom schemes. It is not used in v1 (see section 8).
- `Link` works in medium and large widgets only. A small widget has a single tap target (`widgetURL`).
- Widgets cannot be transparent. Black widget on a black wallpaper is the look.

### Out of scope

Home-screen swipe gestures, double-tap to lock, setting the wallpaper, auto-discovering installed apps, screen-time stats, iPad-specific layouts, lock-screen and Control Center widgets.

## 2. Environment and project setup

- Xcode 26.6 is installed, with an iPhone 17 Pro simulator on iOS 26.5. `xcodegen` is at `/opt/homebrew/bin/xcodegen`.
- Project lives in this folder: `/Users/ulyngs/digital-habits-tools/dh-launcher/`.
- **Generate the Xcode project with XcodeGen** from a `project.yml`. Do not hand-write `project.pbxproj`. Add `*.xcodeproj` to `.gitignore`.
- Deployment target: **iOS 18.0**. Swift 6 language mode, iPhone only, portrait only.
- No third-party dependencies.
- Bundle ID prefix and development team are placeholders in `project.yml` (`org.example.dhlauncher`, empty team). The owner sets the real ones. Simulator builds must work without a team.
- `git init` in this folder. Do not commit unless asked.
- Licence: add `LICENSE` as **MIT** by default and note in the README that the owner may switch (GPL-3.0 would match Olauncher but complicates App Store distribution of outside contributions).

### Targets

| Target | Type | Contents |
|---|---|---|
| `Launcher` | iOS app | Drawer, editor, settings, setup guides, launch forwarding |
| `LauncherWidget` | Widget extension | Home-screen widget |
| `LauncherCore` | Local Swift package, linked by both | Models, store, catalog, URL routing. All unit-tested logic lives here |
| `LauncherCoreTests` | Package tests | Run with `swift test` or `xcodebuild test` |

Both app and widget carry the App Group entitlement `group.<bundle-prefix>` for shared storage.

### Layout

```
dh-launcher/
  project.yml
  README.md  LICENSE  .gitignore
  Launcher/            App.swift, Views/, Assets.xcassets, Info.plist, Launcher.entitlements
  LauncherWidget/      LauncherWidget.swift, Info.plist, LauncherWidget.entitlements
  LauncherCore/        Package.swift, Sources/LauncherCore/, Tests/LauncherCoreTests/
    Sources/LauncherCore/Resources/catalog.json
```

## 3. Core model (`LauncherCore`)

```swift
struct LauncherItem: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String            // text shown in widget and drawer
    var target: LaunchTarget
    var onHomeScreen: Bool      // shown in the widget, or drawer-only
}

enum LaunchTarget: Codable, Hashable {
    case urlScheme(String)      // "spotify://"
    case shortcut(name: String) // runs shortcuts://run-shortcut?name=...
    case web(URL)               // https link, opens in browser or via universal link
}

struct LauncherSettings: Codable {
    var alignment: Alignment    // leading / center / trailing
    var textSize: TextSize      // small / medium / large
    var showDate: Bool
    var theme: Theme            // black / white
}
```

- `LauncherStore`: loads and saves `[LauncherItem]` (ordered) and `LauncherSettings` as JSON files in the App Group container. Takes the directory as an init parameter so tests use a temp directory. Missing or corrupt file returns defaults, never crashes.
- `LaunchRouter`:
  - `widgetURL(for: LauncherItem) -> URL` produces `dhlauncher://open?id=<uuid>`.
  - `parse(_ url: URL) -> UUID?` is the inverse.
  - `destination(for: LaunchTarget) -> URL?` builds the real URL, percent-encoding shortcut names correctly (spaces, `&`, emoji, non-Latin).
- `AppCatalog`: decodes the bundled `catalog.json`, a list of `{ "name": "Spotify", "scheme": "spotify://", "verified": false }`.
  - Seed with ~40 common apps (Apple's own plus popular third-party). Schemes from memory are **unverified**: keep `verified: false` unless confirmed on a simulator or device, and write the README so contributors can correct entries.
  - Do **not** use `canOpenURL` or `LSApplicationQueriesSchemes` (capped at 50 entries). Just attempt to open and handle failure.

## 4. Host app

Black background, white monospaced-free system text, no icons, no chrome. It should feel like Olauncher's drawer.

### Launch forwarding (the critical path)

- Register the `dhlauncher` URL scheme in `Info.plist`.
- `onOpenURL`: parse the ID, look up the item, call `UIApplication.shared.open(destination)` immediately.
- While forwarding, show only a plain black screen, so the bounce is a black flicker rather than a visible UI. The launch screen is also plain black.
- If `open` reports failure, show a "Couldn't open <name>" screen with two actions: edit the item, or open the Shortcut setup guide.
- When the user later returns to the app, show the drawer, not the black screen.

### Screens

1. **Drawer (root)**: all items as a text list, search field focused on appear with the keyboard up. Typing filters. When exactly one item matches, launch it automatically (Olauncher behaviour; make it a setting, default on). Long-press an item to edit, delete, or toggle "on home screen".
2. **Add app**: three routes.
   - *From catalog*: searchable list from `catalog.json`.
   - *Via Shortcut*: user types the app name; app proposes the shortcut name `Open <App>`, shows the step-by-step guide (below), then a "Test" button.
   - *Custom*: name plus URL scheme or https link.
3. **Home screen list**: reorder (drag) and choose which items appear in the widget. Show how many fit per widget size.
4. **Settings**: alignment, text size, show date, theme, auto-launch on single match.
5. **Setup guide**: making the widget the home screen. Steps: set a plain black wallpaper, add the large widget, move other apps to the App Library, remove extra pages. Text and simple illustrations only.
6. **Shortcut guide**: open Shortcuts (`shortcuts://create-shortcut`), add the "Open App" action, pick the app, name the shortcut exactly as shown (copy-to-clipboard button for the name). Then "Test".

Every change to items or settings saves and calls `WidgetCenter.shared.reloadAllTimelines()`.

## 5. Widget

- `StaticConfiguration`, families `.systemMedium` and `.systemLarge` (plus `.systemSmall` showing the first item only, whole widget tappable via `widgetURL`).
- Content: optional date line at the top, then the items flagged `onHomeScreen`, in order, each a `Link` to `LaunchRouter.widgetURL(for:)`.
- Capacity depends on text size; define it in one place in `LauncherCore` (roughly 4 items medium, 8 large at medium text) and truncate. The app's home-screen list uses the same numbers.
- `containerBackground` pure black (or white per theme). Disable content margins as needed so text aligns with the screen edge when left- or right-aligned.
- Support the tinted/clear rendering modes sensibly (`widgetAccentable` on text) so it does not render as a blank block.
- Timeline: a single entry, refreshed at the next midnight if the date is shown. Reloads otherwise come from the app.
- Empty state: "Open DH Launcher to add apps", tappable.

## 6. Milestones

Each milestone ends with the build passing and its checks done. Stop and report if a check cannot be met.

| # | Deliverable | Done when |
|---|---|---|
| 1 | Project skeleton: `project.yml`, three targets, App Group, empty app and widget | `xcodegen generate` and `xcodebuild` for the simulator succeed; app launches on the iPhone 17 Pro simulator |
| 2 | `LauncherCore`: models, store, router, catalog, with unit tests | Tests pass, covering round-trip persistence, corrupt file, URL build/parse, shortcut-name encoding, catalog decoding |
| 3 | Launch forwarding and a hard-coded item list | On the simulator, opening `dhlauncher://open?id=…` via `xcrun simctl openurl` forwards to Maps (`maps://`) and to a test Shortcut |
| 4 | Drawer, add/edit/delete, reorder, settings | Items persist across relaunch; search filters; single-match auto-launch works |
| 5 | Widget in all three sizes, reading shared storage | Widget on the simulator home screen shows the list, updates after an edit in the app, and tapping a row launches the target |
| 6 | Setup guide, Shortcut guide, failure screen | A Shortcut-based item can be created end to end on the simulator following only the in-app guide |
| 7 | README (what it is, limits, build steps, how to contribute catalog entries), licence, app icon placeholder | A fresh clone builds with `xcodegen generate` plus one `xcodebuild` command from the README |

## 7. Verification notes

- Build and unit tests: `xcodebuild` against the iPhone 17 Pro simulator.
- Simulator has Shortcuts and Apple's stock apps but no third-party apps, so test launching with Apple schemes and with a Shortcut. Third-party schemes stay `verified: false`.
- Take simulator screenshots of the drawer and the widget (large, medium) in the black theme for the README.
- The bounce through the host app and through Shortcuts needs judging on a **physical device**; timing on the simulator is not representative. List this in the final report as not verified.

## 8. Later, not now

- **Skip the host-app bounce for universal-link apps**: a widget `Button(intent:)` returning `OpenURLIntent` for items whose target is an https universal link. Needs device testing; reports say it is unreliable for custom schemes.
- **One dispatcher Shortcut instead of one per app**: only possible if the "Open App" action accepts a variable. Unconfirmed; test on device before designing around it.
- Shareable iCloud links to pre-made "Open X" shortcuts.
- Lock-screen and Control Center launch buttons, iPad layouts, localisation.
- App Store / TestFlight release (needs the owner's developer account, real bundle ID and App Group).

## 9. Decisions for the owner

These do not block implementation; placeholders are in place.

1. App name.
2. Bundle ID prefix and Apple developer team.
3. Licence: MIT (default here) or GPL-3.0.
