import SwiftUI

/// "How to use": making the widget the whole home screen (text plus simple
/// drawings), then how to use the app itself.
struct SetupGuideView: View {
    private let name = Bundle.main.displayName

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Make it your home screen").font(.title3.weight(.semibold))
                Text("iOS doesn't allow replacing the home screen, but you can get close: a black wallpaper, one page, and the \(name) widget on it.")
                    .foregroundStyle(.secondary)

                GuideStep(n: 1, title: "Set a plain black wallpaper",
                          text: "Settings › Wallpaper › Add New Wallpaper › Color. Drag to pure black, tap Add, then Set as Wallpaper Pair. (Or touch and hold the home screen and tap Edit › Edit Wallpaper.)") {
                    PhoneSketch { EmptyView() }
                }
                GuideStep(n: 2, title: "Add the large widget",
                          text: "Touch and hold an empty part of the home screen, tap Edit › Add Widget, search for \(name), swipe to the large size and tap Add Widget. Drag it to the top. Tap Done.") {
                    PhoneSketch { WidgetSketch(rows: 7) }
                }
                GuideStep(n: 3, title: "Move other apps to the App Library",
                          text: "Touch and hold each app icon, tap Remove App › Remove from Home Screen. The app stays installed. You can still open it from the App Library, or with Search on the home screen.") {
                    PhoneSketch { WidgetSketch(rows: 7) }
                }
                GuideStep(n: 4, title: "Remove extra pages",
                          text: "Touch and hold the home screen, tap Edit › Edit Pages, and untick every page except the one with the widget. Unticked pages are hidden, not deleted.") {
                    PhoneSketch { WidgetSketch(rows: 7) }
                }
                GuideStep(n: 5, title: "Keep \(name) one tap away",
                          text: "Put \(name) in the dock as the only icon. Open it to change which apps are on the widget. For any other app, tap Search on the home screen.") {
                    PhoneSketch(dockIcon: true) { WidgetSketch(rows: 7) }
                }

                Divider()

                Text("Using \(name)").font(.title3.weight(.semibold))
                VStack(alignment: .leading, spacing: 14) {
                    UseTip(title: "Open an app", text: "Tap its name, on the widget or in \(name).")
                    UseTip(title: "Change the order", text: "In \(name), touch and hold a name and drag it up or down. The widget shows your apps from the top, as many as fit.")
                    UseTip(title: "Edit or remove an app", text: "Touch and hold its name. Removing an app only takes it off the widget; the app itself stays on your iPhone.")
                    UseTip(title: "Add apps", text: "Tap add app and tick the ones you want from the list of common apps.")
                }
                UseTip(title: "Add an app or website that isn't in the list", text: "Tap add app, then Add any app or Add a website. It takes a one-step Shortcut, and the guide shows each tap with a picture.")
            }
            .padding(24)
        }
        .navigationTitle("How to use")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { DoneButton() }
    }
}

private struct GuideStep<Art: View>: View {
    let n: Int
    let title: String
    let text: String
    @ViewBuilder let art: Art

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            art.frame(width: 74)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(n). \(title)").font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

/// A phone outline with a black screen.
private struct PhoneSketch<Content: View>: View {
    var dockIcon = false
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 12).fill(.black)
            RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.6), lineWidth: 1.5)
            content.padding(.top, 14).padding(.horizontal, 8)
            if dockIcon {
                VStack { Spacer(); RoundedRectangle(cornerRadius: 3).fill(.white).frame(width: 12, height: 12).padding(.bottom, 8) }
            }
        }
        .frame(width: 70, height: 140)
        .accessibilityHidden(true)
    }
}

/// The widget: lines of "text" on black.
private struct WidgetSketch: View {
    let rows: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(0..<rows, id: \.self) { i in
                Capsule().fill(.white.opacity(0.85))
                    .frame(width: [30, 22, 26, 18, 28, 20, 24][i % 7], height: 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct UseTip: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(text).font(.subheadline).foregroundStyle(.secondary)
        }
    }
}
