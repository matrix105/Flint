import SwiftUI

// MARK: - Reusable Flint UI Components

struct FlintCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(Color.flintSurface)
            .cornerRadius(16)
    }
}

struct FlintButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void

    enum ButtonStyle {
        case primary
        case secondary
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.flintBody(16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(style == .primary ? Color.flintSpark : Color.flintElevated)
                .foregroundColor(style == .primary ? .white : .flintText)
                .cornerRadius(12)
                .overlay(
                    Group {
                        if style == .secondary {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.flintBorder, lineWidth: 1)
                        }
                    }
                )
        }
    }
}

struct FlintBadgeView: View {
    let badge: FlintBadge

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: badge.iconName)
                .font(.title2)
                .foregroundColor(badge.isUnlocked ? .flintSpark : .flintStone)
            Text(badge.name)
                .font(.flintBody(11))
                .foregroundColor(badge.isUnlocked ? .flintText : .flintStone)
                .lineLimit(1)
        }
        .frame(width: 70, height: 70)
        .background(Color.flintSurface)
        .cornerRadius(12)
        .opacity(badge.isUnlocked ? 1 : 0.5)
    }
}
