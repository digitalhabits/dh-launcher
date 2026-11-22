import Testing
@testable import LauncherCore

struct TypographyTests {
    @Test func bundledBrandFontRegisters() {
        #expect(Typography.registerFonts())
        #expect(Typography.isBrandFontAvailable)
    }

    @Test func brandIsTheDefaultFont() {
        #expect(LauncherSettings.default.fontStyle == .brand)
    }
}
