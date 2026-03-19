import SwiftUI

// MARK: - Spacing

enum FTSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Radius

enum FTRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let full: CGFloat = 100
}

// MARK: - View Modifiers

extension View {
    func ftGlow(color: Color = .flintSpark, radius: CGFloat = 12) -> some View {
        self.shadow(color: color.opacity(0.4), radius: radius)
    }

    func ftCard() -> some View {
        self
            .background(Color.flintSurface)
            .clipShape(RoundedRectangle(cornerRadius: FTRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: FTRadius.lg)
                    .stroke(Color.flintBorder, lineWidth: 1)
            )
    }

    func ftPrivacyShield(isActive: Bool) -> some View {
        self.overlay {
            if isActive {
                ZStack {
                    Color.flintBlack.ignoresSafeArea()
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.flintSpark)
                        Text("Flint")
                            .font(.flintDisplay(20))
                            .foregroundColor(.flintText)
                    }
                }
            }
        }
    }
}
