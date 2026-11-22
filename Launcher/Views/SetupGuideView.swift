import SwiftUI

/// How to make the widget the whole home screen. Text plus simple drawings.
struct SetupGuideView: View {
    private let name = Bundle.main.displayName

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
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
                          text: "Touch and hold each app icon, tap Remove App › Remove from Home Screen. The app stays installed and is still in the App Library and in \(name)'s list.") {
                    PhoneSketch { WidgetSketch(rows: 7) }
                }
                GuideStep(n: 4, title: "Remove extra pages",
                          text: "Touch and hold the home screen, tap Edit › Edit Pages, and untick every page except the one with the widget. Unticked pages are hidden, not deleted.") {
                    PhoneSketch { WidgetSketch(rows: 7) }
                }
                GuideStep(n: 5, title: "Keep the drawer one tap away",
                          text: "Put \(name) in the dock (or leave it as the only icon). Opening it shows every app you've added, with search ready.") {
                    PhoneSketch(dockIcon: true) { WidgetSketch(rows: 7) }
                }
            }
            .padding(24)
        }
        .navigationTitle("Home screen setup")
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
