import SwiftUI

// MARK: - Flint Design Tokens

extension Color {
    // MARK: Backgrounds
    /// Primary background - #0A0A0F
    static let flintBlack = Color(red: 10/255, green: 10/255, blue: 15/255)
    /// Card backgrounds - #12121A
    static let flintSurface = Color(red: 18/255, green: 18/255, blue: 26/255)
    /// Elevated surfaces, sheets - #1A1A26
    static let flintElevated = Color(red: 26/255, green: 26/255, blue: 38/255)
    /// Pressed/hover states - #22222E
    static let flintHover = Color(red: 34/255, green: 34/255, blue: 46/255)

    // MARK: Accent
    /// Primary accent (the spark) - #E94560
    static let flintSpark = Color(red: 233/255, green: 69/255, blue: 96/255)
    /// Lighter accent, highlights - #FF6B81
    static let flintGlow = Color(red: 255/255, green: 107/255, blue: 129/255)
    /// Tinted backgrounds - rgba(233,69,96,0.12)
    static let flintMuted = Color(red: 233/255, green: 69/255, blue: 96/255).opacity(0.12)

    // MARK: Macros
    /// Protein blue - #3B82F6
    static let flintProtein = Color(red: 59/255, green: 130/255, blue: 246/255)
    /// Carbs amber - #F59E0B
    static let flintCarbs = Color(red: 245/255, green: 158/255, blue: 11/255)
    /// Fat purple - #A855F7
    static let flintFat = Color(red: 168/255, green: 85/255, blue: 247/255)

    // MARK: Status
    /// Targets hit - #22C55E
    static let flintSuccess = Color(red: 34/255, green: 197/255, blue: 94/255)
    /// Approaching limit - #F59E0B
    static let flintWarning = Color(red: 245/255, green: 158/255, blue: 11/255)
    /// Over target - #EF4444
    static let flintDanger = Color(red: 239/255, green: 68/255, blue: 68/255)

    // MARK: Text
    /// Primary text - #F0F0F0
    static let flintText = Color(red: 240/255, green: 240/255, blue: 240/255)
    /// Secondary text - #8888A0
    static let flintGrey = Color(red: 136/255, green: 136/255, blue: 160/255)
    /// Tertiary text, hints - #555566
    static let flintStone = Color(red: 85/255, green: 85/255, blue: 102/255)

    // MARK: Borders
    /// Borders - rgba(255,255,255,0.06)
    static let flintBorder = Color.white.opacity(0.06)
    /// Dividers - rgba(255,255,255,0.04)
    static let flintDivider = Color.white.opacity(0.04)
}

// MARK: - Flint Typography

extension Font {
    /// Display font for numbers and hero stats
    static func flintDisplay(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    /// Body text
    static func flintBody(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Monospace for macro numbers
    static func flintMono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}
