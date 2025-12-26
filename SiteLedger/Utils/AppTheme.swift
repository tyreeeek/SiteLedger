import SwiftUI

struct AppTheme {
    // MARK: - Primary Colors
    static let primaryColor = Color(hex: "7C3AED")      // Modern Purple
    static let secondaryColor = Color(hex: "A78BFA")    // Light Purple
    static let accentColor = Color(hex: "06B6D4")       // Cyan
    
    // MARK: - Semantic Colors (adaptive for dark mode)
    static let backgroundColor = Color(UIColor.systemBackground)
    static let cardBackground = Color(UIColor.secondarySystemBackground)
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary = Color(UIColor.tertiaryLabel)
    static let borderColor = Color(UIColor.separator)
    static let dividerColor = Color(UIColor.separator)
    
    // MARK: - Status Colors
    static let successColor = Color(hex: "10B981")      // Emerald
    static let warningColor = Color(hex: "F59E0B")      // Amber
    static let errorColor = Color(hex: "EF4444")        // Red
    static let infoColor = Color(hex: "3B82F6")         // Blue
    
    // MARK: - Semantic Colors (document storage - no income/expense)
    static let positiveColor = Color(hex: "10B981")     // Green - Positive status
    static let negativeColor = Color(hex: "EF4444")     // Red - Negative status
    static let neutral = Color(hex: "6B7280")           // Gray - Neutral
    
    // MARK: - Financial Colors (labor cost based - no income/expense)
    static let profitColor = Color(hex: "10B981")       // Green - Profit
    static let laborCostColor = Color(hex: "F59E0B")    // Amber - Labor costs
    static let alertColor = Color(hex: "EF4444")        // Red - Alerts/warnings
    
    // MARK: - Layout Constants
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let largeCornerRadius: CGFloat = 16
    
    static let cardPadding: CGFloat = 16
    static let spacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    static let largeSpacing: CGFloat = 24
    
    // MARK: - Shadow
    static let shadowColor = Color.black.opacity(0.08)
    static let shadowRadius: CGFloat = 8
    static let shadowOffset = CGSize(width: 0, height: 2)
    
    // MARK: - Typography
    static let titleFont = Font.system(size: 32, weight: .bold)
    static let headlineFont = Font.system(size: 24, weight: .bold)
    static let subheadlineFont = Font.system(size: 20, weight: .semibold)
    static let bodyFont = Font.system(size: 16, weight: .regular)
    static let captionFont = Font.system(size: 14, weight: .regular)
    static let smallCaptionFont = Font.system(size: 12, weight: .regular)
}
