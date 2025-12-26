import SwiftUI

// MARK: - Reusable Settings Components

/// Standard row for settings screens with icon, title, subtitle, and trailing content
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let trailing: AnyView?
    let action: (() -> Void)?
    
    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        trailing: AnyView? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.light()
            action?()
        }) {
            HStack(spacing: DesignSystem.Spacing.standard) {
                // Icon Circle
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(
                            width: DesignSystem.Layout.iconCircleSize,
                            height: DesignSystem.Layout.iconCircleSize
                        )
                    
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.TextStyle.bodyBold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(DesignSystem.TextStyle.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Trailing Content
                if let trailing {
                    trailing
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Section container for settings screens with optional header
struct SettingsSection<Content: View>: View {
    let title: String?
    let content: Content
    
    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            if let title {
                Text(title.uppercased())
                    .font(DesignSystem.TextStyle.sectionHeader)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
            }
            
            VStack(spacing: 0) {
                content
                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                    .padding(.vertical, DesignSystem.Spacing.small)
            }
            .cardStyle()
        }
    }
}

/// Toggle row for settings
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.standard) {
            // Icon Circle
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(
                        width: DesignSystem.Layout.iconCircleSize,
                        height: DesignSystem.Layout.iconCircleSize
                    )
                
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.TextStyle.bodyBold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if let subtitle {
                    Text(subtitle)
                        .font(DesignSystem.TextStyle.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(DesignSystem.Colors.primary)
                .onChange(of: isOn) {
                    HapticsManager.shared.light()
                }
        }
        .padding(.vertical, 10)
    }
}

/// Info banner for hints and warnings
struct InfoBanner: View {
    enum Style {
        case info
        case warning
        case success
        case error
        
        var color: Color {
            switch self {
            case .info: return DesignSystem.Colors.info
            case .warning: return DesignSystem.Colors.warning
            case .success: return DesignSystem.Colors.success
            case .error: return DesignSystem.Colors.destructive
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
    }
    
    let style: Style
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: style.icon)
                .foregroundColor(style.color)
                .font(.system(size: 16))
            
            Text(message)
                .font(DesignSystem.TextStyle.caption)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
        .padding(DesignSystem.Spacing.medium)
        .background(style.color.opacity(0.1))
        .cornerRadius(DesignSystem.Layout.mediumRadius)
    }
}

/// Profile card for user display
struct ProfileCard: View {
    let name: String
    let email: String
    let memberSince: String
    let role: String?
    let phone: String?
    let photoURL: String?
    let onTap: () -> Void
    
    init(name: String, email: String, memberSince: String, role: String? = nil, phone: String? = nil, photoURL: String? = nil, onTap: @escaping () -> Void) {
        self.name = name
        self.email = email
        self.memberSince = memberSince
        self.role = role
        self.phone = phone
        self.photoURL = photoURL
        self.onTap = onTap
    }
    
    private var initials: String {
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return initials.isEmpty ? "?" : String(initials).uppercased()
    }
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.light()
            onTap()
        }) {
            VStack(spacing: 10) {
                // Profile Image with Role Badge
                ZStack(alignment: .bottomTrailing) {
                    if let photoURL = photoURL, let url = URL(string: photoURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(
                                        width: DesignSystem.Layout.profileImageSize,
                                        height: DesignSystem.Layout.profileImageSize
                                    )
                                    .clipShape(Circle())
                            default:
                                defaultAvatarView
                            }
                        }
                    } else {
                        defaultAvatarView
                    }
                    
                    // Role Badge
                    if let role = role {
                        HStack(spacing: 4) {
                            Image(systemName: role.lowercased() == "owner" ? "crown.fill" : "hammer.fill")
                                .font(.system(size: 10))
                            Text(role)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            role.lowercased() == "owner" ? DesignSystem.Colors.primary : DesignSystem.Colors.blue
                        )
                        .cornerRadius(12)
                        .offset(x: 5, y: 5)
                    }
                }
                
                // Name
                Text(name)
                    .font(DesignSystem.TextStyle.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                // Email
                Text(email)
                    .font(DesignSystem.TextStyle.bodySecondary)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                // Phone (if available)
                if let phone = phone, !phone.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 12))
                        Text(phone)
                            .font(DesignSystem.TextStyle.bodySecondary)
                    }
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                // Member Since
                Text(memberSince)
                    .font(DesignSystem.TextStyle.tiny)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.large)
        }
        .buttonStyle(PlainButtonStyle())
        .cardStyle()
    }
    
    private var defaultAvatarView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [DesignSystem.Colors.primary, DesignSystem.Colors.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(
                    width: DesignSystem.Layout.profileImageSize,
                    height: DesignSystem.Layout.profileImageSize
                )
            
            Text(initials)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

/// Loading state overlay
struct LoadingOverlay: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.medium) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                if let message {
                    Text(message)
                        .font(DesignSystem.TextStyle.bodySecondary)
                        .foregroundColor(.white)
                }
            }
            .padding(DesignSystem.Spacing.extraLarge)
            .background(.ultraThinMaterial)
            .cornerRadius(DesignSystem.Layout.cardRadius)
        }
    }
}
