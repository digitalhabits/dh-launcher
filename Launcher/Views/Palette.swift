import SwiftUI
import UIKit
import LauncherCore

/// Foreground/background colours for the chosen theme.
struct Palette {
    let background: Color
    let foreground: Color
    let secondary: Color

    init(_ theme: LauncherSettings.Theme) {
        switch theme {
        case .black:
            background = .black; foreground = .white; secondary = Color(white: 0.55)
        case .white:
            background = .white; foreground = .black; secondary = Color(white: 0.45)
        }
    }
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = Palette(.black)
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

extension LauncherSettings.TextSize {
    var drawerSize: CGFloat {
        switch self {
        case .small: 20
        case .medium: 26
        case .large: 32
        }
    }
}

extension LauncherSettings {
    /// The app's own text is sized for iPhone; on iPad everything is drawn larger so it reads the same.
    @MainActor static let screenScale: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 1.6 : 1

    /// Item names in the drawer. Light in the system font; the brand font starts at Regular.
    @MainActor var drawerFont: Font {
        Typography.font(fontStyle, size: textSize.drawerSize * Self.screenScale, weight: fontStyle == .system ? .light : .regular)
    }

    /// Any other text drawn in the launcher's own style.
    @MainActor func font(size: CGFloat, weight: Font.Weight? = nil) -> Font {
        Typography.font(fontStyle, size: size * Self.screenScale, weight: weight ?? (fontStyle == .system ? .light : .regular))
    }
}

extension LauncherSettings.Alignment {
    var horizontal: HorizontalAlignment {
        switch self { case .leading: .leading; case .center: .center; case .trailing: .trailing }
    }
    var frame: Alignment {
        switch self { case .leading: .leading; case .center: .center; case .trailing: .trailing }
    }
    var text: TextAlignment {
        switch self { case .leading: .leading; case .center: .center; case .trailing: .trailing }
    }
}
