import SwiftUI

// MARK: - Design System
/// Centralized design tokens for consistent UI across the app

struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Primary Brand
        static let primary = Color(hex: "3B82F6")       // Blue - CTAs and primary actions
        static let primaryLight = Color(hex: "60A5FA")  // Light blue for subtle accents
        
        // Backgrounds - Use system colors for proper dark mode support
        static let background = Color(UIColor.systemBackground)
        static let cardBackground = Color(UIColor.secondarySystemBackground)
        static let cardBackgroundDark = Color(UIColor.tertiarySystemBackground)
        
        // Text - Use system colors for proper dark mode support
        static let textPrimary = Color(UIColor.label)
        static let textSecondary = Color(UIColor.secondaryLabel)
        static let textTertiary = Color(UIColor.tertiaryLabel)
        
        // Semantic Colors (document storage - no income/expense)
        static let positive = Color(hex: "10B981")      // Green - positive status
        static let negative = Color(hex: "EF4444")      // Red - negative status
        static let warning = Color(hex: "F59E0B")       // Orange - warnings
        static let info = Color(hex: "3B82F6")          // Blue - info
        static let success = Color(hex: "10B981")       // Green - success
        static let destructive = Color.red              // Red - destructive actions
        
        // Accent Colors (for icons)
        static let purple = Color(hex: "8B5CF6")
        static let blue = Color(hex: "3B82F6")
        static let cyan = Color(hex: "06B6D4")
        static let teal = Color(hex: "14B8A6")
        static let pink = Color(hex: "EC4899")
        static let orange = Color(hex: "F59E0B")
        static let green = Color(hex: "10B981")
    }
    
    // MARK: - Typography
    struct TextStyle {
        // Large Titles
        static let title1 = Font.system(size: 34, weight: .bold)           // Main screen titles
        static let title2 = Font.system(size: 22, weight: .bold)           // Section headings
        static let title3 = Font.system(size: 20, weight: .semibold)       // Card titles
        
        // Body Text
        static let bodyPrimary = Font.system(size: 16, weight: .regular)   // Main content
        static let bodySecondary = Font.system(size: 15, weight: .regular) // Secondary content
        static let bodyBold = Font.system(size: 16, weight: .semibold)     // Emphasized content
        
        // Small Text
        static let caption = Font.system(size: 14, weight: .regular)       // Small descriptions
        static let captionBold = Font.system(size: 14, weight: .semibold)  // Small labels
        static let tiny = Font.system(size: 12, weight: .regular)          // Timestamps, meta
        
        // Labels
        static let sectionHeader = Font.system(size: 13, weight: .semibold) // ALL CAPS section headers
        static let buttonLabel = Font.system(size: 16, weight: .semibold)   // Button text
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let tiny: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let standard: CGFloat = 16
        static let large: CGFloat = 20
        static let extraLarge: CGFloat = 24
        static let huge: CGFloat = 32
        
        // Card Specific
        static let cardPadding: CGFloat = 16
        static let cardSpacing: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
    }
    
    // MARK: - Layout
    struct Layout {
        static let cardRadius: CGFloat = 24
        static let mediumRadius: CGFloat = 16
        static let smallRadius: CGFloat = 12
        static let buttonRadius: CGFloat = 16
        
        static let buttonHeight: CGFloat = 56
        static let rowHeight: CGFloat = 60
        static let iconCircleSize: CGFloat = 36
        static let profileImageSize: CGFloat = 72
        
        static let minTapTarget: CGFloat = 44
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let color = Color.black.opacity(0.04)
        static let radius: CGFloat = 18
        static let x: CGFloat = 0
        static let y: CGFloat = 8
        
        static func apply() -> some View {
            EmptyView()
                .shadow(color: color, radius: radius, x: x, y: y)
        }
    }
    
    // MARK: - Animation
    struct Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.2)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.Layout.cardRadius)
            .shadow(
                color: DesignSystem.Shadow.color,
                radius: DesignSystem.Shadow.radius,
                x: DesignSystem.Shadow.x,
                y: DesignSystem.Shadow.y
            )
    }
    
    func primaryButtonStyle() -> some View {
        self
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Layout.buttonHeight)
            .background(DesignSystem.Colors.primary)
            .foregroundColor(.white)
            .cornerRadius(DesignSystem.Layout.buttonRadius)
            .font(DesignSystem.TextStyle.buttonLabel)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Layout.buttonHeight)
            .background(DesignSystem.Colors.primary.opacity(0.1))
            .foregroundColor(DesignSystem.Colors.primary)
            .cornerRadius(DesignSystem.Layout.buttonRadius)
            .font(DesignSystem.TextStyle.buttonLabel)
    }
    
    func destructiveButtonStyle() -> some View {
        self
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Layout.buttonHeight)
            .background(DesignSystem.Colors.destructive.opacity(0.1))
            .foregroundColor(DesignSystem.Colors.destructive)
            .cornerRadius(DesignSystem.Layout.buttonRadius)
            .font(DesignSystem.TextStyle.buttonLabel)
    }
}
