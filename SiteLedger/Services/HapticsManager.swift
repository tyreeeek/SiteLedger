//
//  HapticsManager.swift
//  SiteLedger
//
//  Created on November 25, 2025.
//

import SwiftUI

/// Centralized haptic feedback manager for consistent tactile responses throughout the app
final class HapticsManager {
    static let shared = HapticsManager()
    
    private init() {}
    
    // MARK: - Notification Feedback
    
    /// Success feedback (e.g., job created, receipt uploaded, timesheet submitted)
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warning feedback (e.g., budget approaching limit, missing data)
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Error feedback (e.g., upload failed, validation error)
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Impact Feedback
    
    /// Light impact (e.g., button taps, toggles)
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium impact (e.g., list selections, tab switches)
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy impact (e.g., important actions like check-in/check-out)
    func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Soft impact (e.g., subtle UI interactions)
    func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    /// Rigid impact (e.g., definitive actions like delete)
    func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    // MARK: - Selection Feedback
    
    /// Selection feedback (e.g., picker scrolling, segmented control changes)
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - View Extension for Easy Access

extension View {
    /// Add haptic feedback to any view interaction
    func haptic(_ type: HapticType) -> some View {
        self.onTapGesture {
            HapticsManager.shared.trigger(type)
        }
    }
}

// MARK: - Haptic Type Enum

enum HapticType {
    case success
    case warning
    case error
    case light
    case medium
    case heavy
    case soft
    case rigid
    case selection
}

extension HapticsManager {
    /// Generic trigger method for HapticType enum
    func trigger(_ type: HapticType) {
        switch type {
        case .success: success()
        case .warning: warning()
        case .error: error()
        case .light: light()
        case .medium: medium()
        case .heavy: heavy()
        case .soft: soft()
        case .rigid: rigid()
        case .selection: selection()
        }
    }
}
