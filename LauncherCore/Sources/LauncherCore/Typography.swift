import CoreText
import Foundation
import SwiftUI

/// Fonts shared by the app and the widget. The brand font (Schibsted Grotesk,
/// SIL Open Font Licence, the same font as the Digital Habits website) ships in
/// this package's resources and is registered for the current process on first use.
public enum Typography {
    public static let brandFamily = "Schibsted Grotesk"

    /// Registers the bundled font once per process. Safe to call repeatedly.
    @discardableResult
    public static func registerFonts() -> Bool { registered }

    private static let registered: Bool = {
        guard let url = Bundle.module.url(forResource: "SchibstedGrotesk", withExtension: "ttf", subdirectory: "Fonts")
                ?? Bundle.module.url(forResource: "SchibstedGrotesk", withExtension: "ttf")
        else { return false }
        var error: Unmanaged<CFError>?
        let ok = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        // "Already registered" also counts as success.
        return ok || isBrandFontAvailable
    }()

    static var isBrandFontAvailable: Bool {
        let descriptor = CTFontDescriptorCreateWithAttributes([kCTFontFamilyNameAttribute: brandFamily] as CFDictionary)
        let matches = CTFontDescriptorCreateMatchingFontDescriptors(descriptor, nil) as? [CTFontDescriptor]
        return !(matches ?? []).isEmpty
    }

    /// A font in the chosen style. The brand font's lightest weight is Regular,
    /// so lighter requests fall back to Regular.
    public static func font(_ style: LauncherSettings.FontStyle, size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch style {
        case .system:
            return .system(size: size, weight: weight)
        case .brand:
            registerFonts()
            return .custom(brandFamily, fixedSize: size).weight(weight)
        }
    }
}
