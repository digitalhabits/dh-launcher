import SwiftUI
import LauncherCore

@main
struct LauncherApp: App {
    @State private var model = LauncherModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .onOpenURL { model.handle(url: $0) }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .background: model.didEnterBackground()
                    default: break
                    }
                }
        }
    }
}

struct RootView: View {
    @Environment(LauncherModel.self) private var model

    var body: some View {
        let palette = Palette(model.settings.theme)
        ZStack {
            palette.background.ignoresSafeArea()
            switch model.phase {
            case .forwarding:
                // Deliberately empty: the hand-off should read as a black flicker.
                Color.black.ignoresSafeArea()
            case .failed(let item):
                FailureView(item: item)
            case .drawer:
                DrawerView()
            }
        }
        .sheet(item: Binding(get: { model.sheet }, set: { model.sheet = $0 })) { sheet in
            SheetContent(sheet: sheet)
                .environment(model)
                .environment(\.palette, palette)
                .preferredColorScheme(model.settings.theme == .black ? .dark : .light)
        }
        .environment(\.palette, palette)
        .preferredColorScheme(model.settings.theme == .black ? .dark : .light)
    }
}
