import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("defaultCurrency") private var defaultCurrency = "USD"
    @AppStorage("dateFormat") private var dateFormat = "MM/dd/yyyy"
    @State private var cacheSize = "0 MB"
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        // Appearance
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Appearance",
                                    subtitle: "Customize how the app looks"
                                )
                                
                                NotificationToggle(
                                    icon: "moon.fill",
                                    title: "Dark Mode",
                                    subtitle: "Use dark theme",
                                    color: Color.purple,
                                    isOn: $isDarkMode
                                )
                                
                                NotificationToggle(
                                    icon: "hand.tap.fill",
                                    title: "Haptic Feedback",
                                    subtitle: "Vibration on interactions",
                                    color: ModernDesign.Colors.primary,
                                    isOn: $hapticFeedback
                                )
                            }
                        }
                        
                        // Regional Settings
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Regional",
                                    subtitle: "Currency and date preferences"
                                )
                                
                                // Currency Picker
                                VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                    Text("Currency")
                                        .font(ModernDesign.Typography.labelSmall)
                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                    
                                    Picker("Currency", selection: $defaultCurrency) {
                                        Text("USD ($)").tag("USD")
                                        Text("EUR (€)").tag("EUR")
                                        Text("GBP (£)").tag("GBP")
                                        Text("CAD ($)").tag("CAD")
                                        Text("AUD ($)").tag("AUD")
                                    }
                                    .pickerStyle(.menu)
                                    .padding(ModernDesign.Spacing.md)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(ModernDesign.Colors.background)
                                    .cornerRadius(ModernDesign.Radius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ModernDesign.Radius.medium)
                                            .stroke(ModernDesign.Colors.border, lineWidth: 1)
                                    )
                                }
                                
                                // Date Format Picker
                                VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                    Text("Date Format")
                                        .font(ModernDesign.Typography.labelSmall)
                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                    
                                    Picker("Date Format", selection: $dateFormat) {
                                        Text("MM/DD/YYYY").tag("MM/dd/yyyy")
                                        Text("DD/MM/YYYY").tag("dd/MM/yyyy")
                                        Text("YYYY-MM-DD").tag("yyyy-MM-dd")
                                    }
                                    .pickerStyle(.menu)
                                    .padding(ModernDesign.Spacing.md)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(ModernDesign.Colors.background)
                                    .cornerRadius(ModernDesign.Radius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ModernDesign.Radius.medium)
                                            .stroke(ModernDesign.Colors.border, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        
                        // Data & Storage
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Data & Storage",
                                    subtitle: "Manage app data"
                                )
                                
                                HStack(spacing: ModernDesign.Spacing.md) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: ModernDesign.Radius.small)
                                            .fill(ModernDesign.Colors.info.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "internaldrive.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(ModernDesign.Colors.info)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Storage Used")
                                            .font(ModernDesign.Typography.label)
                                            .foregroundColor(ModernDesign.Colors.textPrimary)
                                        
                                        Text("\(cacheSize) of cached data")
                                            .font(ModernDesign.Typography.caption)
                                            .foregroundColor(ModernDesign.Colors.textTertiary)
                                    }
                                    
                                    Spacer()
                                }
                                
                                Button(action: {
                                    HapticsManager.shared.medium()
                                    // Clear URL cache
                                    URLCache.shared.removeAllCachedResponses()
                                    // Clear image cache
                                    URLCache.shared.diskCapacity = 0
                                    URLCache.shared.memoryCapacity = 0
                                    // Reset cache size
                                    URLCache.shared.diskCapacity = 100 * 1024 * 1024 // 100MB
                                    URLCache.shared.memoryCapacity = 50 * 1024 * 1024 // 50MB
                                    // Clear API key cache
                                    APIKeyManager.shared.clearCache()
                                    // Update cache size display
                                    cacheSize = "0 MB"
                                    HapticsManager.shared.success()
                                }) {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                        Text("Clear Cache")
                                    }
                                    .font(ModernDesign.Typography.label)
                                    .foregroundColor(ModernDesign.Colors.error)
                                    .frame(maxWidth: .infinity)
                                    .padding(ModernDesign.Spacing.md)
                                    .background(ModernDesign.Colors.error.opacity(0.1))
                                    .cornerRadius(ModernDesign.Radius.medium)
                                }
                            }
                        }
                        
                        // About Section
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.md) {
                                ModernSectionHeader(title: "About")
                                
                                AboutRow(label: "Version", value: "1.0.0")
                                AboutRow(label: "Build", value: "2024.01.15")
                                AboutRow(label: "Device", value: UIDevice.current.model)
                                AboutRow(label: "iOS Version", value: UIDevice.current.systemVersion)
                            }
                        }
                    }
                    .padding(ModernDesign.Spacing.lg)
                    .padding(.bottom, ModernDesign.Spacing.xxxl)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        HapticsManager.shared.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                    }
                }
            }
            .onAppear {
                updateCacheSize()
            }
        }
    }
    
    private func updateCacheSize() {
        let cacheBytes = URLCache.shared.currentDiskUsage + URLCache.shared.currentMemoryUsage
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB]
        formatter.countStyle = .file
        cacheSize = formatter.string(fromByteCount: Int64(cacheBytes))
    }
}

struct AboutRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(ModernDesign.Typography.body)
                .foregroundColor(ModernDesign.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(ModernDesign.Typography.body)
                .foregroundColor(ModernDesign.Colors.textPrimary)
        }
        .padding(.vertical, ModernDesign.Spacing.xs)
    }
}
