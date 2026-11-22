import SwiftUI
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
    var drawerFont: Font {
        switch self {
        case .small: .system(size: 20, weight: .light)
        case .medium: .system(size: 26, weight: .light)
        case .large: .system(size: 32, weight: .light)
        }
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
