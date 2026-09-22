import SwiftUI

public enum ActionButtonStyle {
    case primary
    case secondary
    case success
    case destructive

    public var backgroundColor: Color {
        switch self {
        case .primary: return Color.orange
        case .secondary: return Color(uiColor: .secondarySystemBackground)
        case .success: return Color.green
        case .destructive: return Color.red
        }
    }

    public var foregroundColor: Color {
        switch self {
        case .primary: return Color.black
        case .secondary: return Color.primary
        case .success: return Color.black
        case .destructive: return Color.white
        }
    }
}

public struct BigActionButton: View {
    public let title: String
    public let systemImage: String?
    public let style: ActionButtonStyle
    public let action: () -> Void

    public init(
        title: String,
        systemImage: String? = nil,
        style: ActionButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.headline.weight(.bold))
                }
                Text(title)
                    .font(.headline.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
