
//
//  ModernDesignSystem.swift
//  SiteLedger
//
//  Complete Modern Design System
//

import SwiftUI

struct ModernDesign {
    // MARK: - Colors (Adaptive for Dark Mode using system colors)
    struct Colors {
        // Primary Brand (same for both modes)
        static let primary = Color(hex: "3B82F6")      // Vibrant Blue
        static let primaryLight = Color(hex: "60A5FA")
        static let primaryDark = Color(hex: "2563EB")
        
        // Accent
        static let accent = Color(hex: "F59E0B")       // Yellow/Gold
        static let accentLight = Color(hex: "FCD34D")
        
        // Semantic Colors (same for both modes)
        static let success = Color(hex: "10B981")      // Green
        static let warning = Color(hex: "F59E0B")      // Orange
        static let error = Color(hex: "EF4444")        // Red
        static let info = Color(hex: "3B82F6")         // Blue
        
        // Background - Use system colors for proper dark mode support
        static let background = Color(UIColor.systemBackground)
        static let cardBackground = Color(UIColor.secondarySystemBackground)
        static let secondaryBackground = Color(UIColor.tertiarySystemBackground)
        
        // Text - Use system colors for proper dark mode support
        static let textPrimary = Color(UIColor.label)
        static let textSecondary = Color(UIColor.secondaryLabel)
        static let textTertiary = Color(UIColor.tertiaryLabel)
        
        // Border - Use system colors for proper dark mode support
        static let border = Color(UIColor.separator)
        static let borderLight = Color(UIColor.opaqueSeparator)
    }
    
    // MARK: - Typography
    struct Typography {
        // Display
        static let displayLarge = Font.system(size: 32, weight: .bold)
        static let displayMedium = Font.system(size: 28, weight: .bold)
        
        // Titles
        static let title1 = Font.system(size: 24, weight: .bold)
        static let title2 = Font.system(size: 20, weight: .semibold)
        static let title3 = Font.system(size: 18, weight: .semibold)
        
        // Body
        static let bodyLarge = Font.system(size: 17, weight: .regular)
        static let body = Font.system(size: 15, weight: .regular)
        static let bodySmall = Font.system(size: 14, weight: .regular)
        
        // Labels
        static let labelLarge = Font.system(size: 15, weight: .semibold)
        static let label = Font.system(size: 13, weight: .semibold)
        static let labelSmall = Font.system(size: 11, weight: .semibold)
        
        // Caption
        static let caption = Font.system(size: 12, weight: .regular)
        static let captionSmall = Font.system(size: 10, weight: .regular)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 20
        static let round: CGFloat = 999
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let small = (color: Color.black.opacity(0.05), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let medium = (color: Color.black.opacity(0.08), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let large = (color: Color.black.opacity(0.12), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    }
}

// MARK: - Modern Card
struct ModernCard<Content: View>: View {
    let content: Content
    var backgroundColor: Color = ModernDesign.Colors.cardBackground
    var padding: CGFloat = ModernDesign.Spacing.lg
    var shadow: Bool = true
    
    init(
        backgroundColor: Color = ModernDesign.Colors.cardBackground,
        padding: CGFloat = ModernDesign.Spacing.lg,
        shadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.padding = padding
        self.shadow = shadow
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(ModernDesign.Radius.large)
            .shadow(
                color: shadow ? ModernDesign.Shadow.medium.color : .clear,
                radius: shadow ? ModernDesign.Shadow.medium.radius : 0,
                x: shadow ? ModernDesign.Shadow.medium.x : 0,
                y: shadow ? ModernDesign.Shadow.medium.y : 0
            )
    }
}

// MARK: - Modern Button
struct ModernButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let size: ButtonSize
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    enum ButtonStyle {
        case primary, secondary, outline, ghost, danger
    }
    
    enum ButtonSize {
        case small, medium, large
    }
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.medium()
            action()
        }) {
            HStack(spacing: ModernDesign.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(iconFont)
                }
                Text(title)
                    .font(textFont)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: size == .small ? nil : .infinity)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .foregroundColor(textColor)
            .background(buttonBackground)
            .cornerRadius(ModernDesign.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ModernDesign.Radius.medium)
                    .stroke(borderColor, lineWidth: style == .outline ? 1.5 : 0)
            )
        }
        .disabled(isLoading || isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
    
    private var textFont: Font {
        switch size {
        case .small: return ModernDesign.Typography.labelSmall
        case .medium: return ModernDesign.Typography.label
        case .large: return ModernDesign.Typography.labelLarge
        }
    }
    
    private var iconFont: Font {
        switch size {
        case .small: return .system(size: 12)
        case .medium: return .system(size: 14)
        case .large: return .system(size: 16)
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return ModernDesign.Spacing.md
        case .medium: return ModernDesign.Spacing.lg
        case .large: return ModernDesign.Spacing.xl
        }
    }
    
    private var verticalPadding: CGFloat {
        switch size {
        case .small: return ModernDesign.Spacing.sm
        case .medium: return ModernDesign.Spacing.md
        case .large: return ModernDesign.Spacing.lg
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .white
        case .outline: return ModernDesign.Colors.primary
        case .ghost: return ModernDesign.Colors.primary
        case .danger: return .white
        }
    }
    
    private var buttonBackground: Color {
        switch style {
        case .primary: return ModernDesign.Colors.primary
        case .secondary: return ModernDesign.Colors.textSecondary
        case .outline: return .clear
        case .ghost: return ModernDesign.Colors.primary.opacity(0.1)
        case .danger: return ModernDesign.Colors.error
        }
    }
    
    private var borderColor: Color {
        style == .outline ? ModernDesign.Colors.primary : .clear
    }
}

// MARK: - Modern Badge
struct ModernBadge: View {
    let text: String
    let color: Color
    let size: BadgeSize
    
    enum BadgeSize {
        case small, medium, large
    }
    
    var body: some View {
        Text(text)
            .font(font)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(color)
            .cornerRadius(ModernDesign.Radius.small)
    }
    
    private var font: Font {
        switch size {
        case .small: return ModernDesign.Typography.captionSmall
        case .medium: return ModernDesign.Typography.caption
        case .large: return ModernDesign.Typography.labelSmall
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return ModernDesign.Spacing.sm
        case .medium: return ModernDesign.Spacing.md
        case .large: return ModernDesign.Spacing.lg
        }
    }
    
    private var verticalPadding: CGFloat {
        switch size {
        case .small: return ModernDesign.Spacing.xs
        case .medium: return ModernDesign.Spacing.sm
        case .large: return ModernDesign.Spacing.md
        }
    }
}

// MARK: - Modern Section Header
struct ModernSectionHeader: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(title: String, subtitle: String? = nil, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                Text(title)
                    .font(ModernDesign.Typography.title3)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
                    .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                        .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            if let action = action, let actionTitle = actionTitle {
                Button(action: {
                    HapticsManager.shared.light()
                    action()
                }) {
                    Text(actionTitle)
                        .font(ModernDesign.Typography.label)
                        .foregroundColor(ModernDesign.Colors.primary)
                }
            }
        }
    }
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - UIColor Hex Extension (for dynamic trait-aware colors)
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
