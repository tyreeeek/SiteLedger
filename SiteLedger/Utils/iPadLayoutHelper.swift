//
//  iPadLayoutHelper.swift
//  SiteLedger
//
//  iPad-specific layout utilities for responsive design
//

import SwiftUI

/// Provides iPad-aware layout utilities
enum iPadLayoutHelper {
    
    /// Check if device is an iPad
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// Get adaptive padding based on device
    static func adaptivePadding(_ size: PaddingSize = .medium) -> CGFloat {
        switch size {
        case .small:
            return isIPad ? ModernDesign.Spacing.md : ModernDesign.Spacing.sm
        case .medium:
            return isIPad ? ModernDesign.Spacing.xl : ModernDesign.Spacing.lg
        case .large:
            return isIPad ? ModernDesign.Spacing.xxl : ModernDesign.Spacing.xl
        }
    }
    
    /// Get adaptive font size multiplier for iPad
    static var fontSizeMultiplier: CGFloat {
        isIPad ? 1.15 : 1.0
    }
    
    /// Get adaptive spacing based on device
    static func adaptiveSpacing(_ size: SpacingSize = .medium) -> CGFloat {
        switch size {
        case .small:
            return isIPad ? ModernDesign.Spacing.sm : ModernDesign.Spacing.xs
        case .medium:
            return isIPad ? ModernDesign.Spacing.lg : ModernDesign.Spacing.md
        case .large:
            return isIPad ? ModernDesign.Spacing.xxl : ModernDesign.Spacing.xl
        }
    }
    
    /// Get adaptive column count for grids
    static func gridColumns(min: Int = 2, max: Int = 4) -> Int {
        isIPad ? max : min
    }
    
    /// Get minimum scale factor for text
    static var textMinimumScaleFactor: CGFloat {
        isIPad ? 0.8 : 0.7
    }
    
    enum PaddingSize {
        case small, medium, large
    }
    
    enum SpacingSize {
        case small, medium, large
    }
}

/// View modifier for adaptive text that prevents truncation on iPad
struct AdaptiveTextModifier: ViewModifier {
    let allowsMultipleLines: Bool
    let minimumScaleFactor: CGFloat
    
    init(allowsMultipleLines: Bool = true, minimumScaleFactor: CGFloat = 0.8) {
        self.allowsMultipleLines = allowsMultipleLines
        self.minimumScaleFactor = minimumScaleFactor
    }
    
    func body(content: Content) -> some View {
        if allowsMultipleLines {
            content
                .lineLimit(nil)
                .minimumScaleFactor(minimumScaleFactor)
        } else {
            content
                .lineLimit(1)
                .minimumScaleFactor(minimumScaleFactor)
        }
    }
}

/// View modifier for adaptive layout that adjusts for iPad
struct AdaptiveLayoutModifier: ViewModifier {
    let horizontalPadding: CGFloat
    let verticalSpacing: CGFloat
    
    init(horizontalPadding: iPadLayoutHelper.PaddingSize = .medium,
         verticalSpacing: iPadLayoutHelper.SpacingSize = .medium) {
        self.horizontalPadding = iPadLayoutHelper.adaptivePadding(horizontalPadding)
        self.verticalSpacing = iPadLayoutHelper.adaptiveSpacing(verticalSpacing)
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
    }
}

extension View {
    /// Makes text adaptive for iPad, preventing truncation
    /// - Parameters:
    ///   - allowsMultipleLines: Whether text can wrap to multiple lines (default: true)
    ///   - minimumScaleFactor: Minimum scale factor for text (default: 0.8)
    func adaptiveText(allowsMultipleLines: Bool = true, minimumScaleFactor: CGFloat = 0.8) -> some View {
        self.modifier(AdaptiveTextModifier(allowsMultipleLines: allowsMultipleLines, minimumScaleFactor: minimumScaleFactor))
    }
    
    /// Applies adaptive padding for iPad
    func adaptiveLayout(horizontalPadding: iPadLayoutHelper.PaddingSize = .medium,
                       verticalSpacing: iPadLayoutHelper.SpacingSize = .medium) -> some View {
        self.modifier(AdaptiveLayoutModifier(horizontalPadding: horizontalPadding, verticalSpacing: verticalSpacing))
    }
}
