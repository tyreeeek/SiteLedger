import SwiftUI
import UIKit

// MARK: - Company Profile View
struct CompanyProfileView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("companyName") private var companyName = ""
    @AppStorage("businessType") private var businessType = "General Contractor"
    @AppStorage("defaultCurrency") private var defaultCurrency = "USD"
    @AppStorage("timezone") private var timezone = "America/New_York"
    @AppStorage("workingHoursStart") private var workingHoursStart = 8
    @AppStorage("workingHoursEnd") private var workingHoursEnd = 17
    @AppStorage("companyLogoURL") private var companyLogoURL = ""
    
    @State private var showingSaveSuccess = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingPhotoOptions = false
    @State private var selectedImage: UIImage?
    @State private var isUploadingLogo = false
    
    private let apiService = APIService.shared
    
    let businessTypes = ["General Contractor", "Electrician", "Plumber", "HVAC", "Roofing", "Landscaping", "Painting", "Remodeling", "Other"]
    let currencies = ["USD", "CAD", "EUR", "GBP", "AUD"]
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    // Company Logo
                    ModernCard(shadow: true) {
                        VStack(spacing: ModernDesign.Spacing.md) {
                            Button(action: { showingPhotoOptions = true }) {
                                ZStack {
                                    if let selectedImage = selectedImage {
                                        Image(uiImage: selectedImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(Circle())
                                    } else if !companyLogoURL.isEmpty, let url = URL(string: companyLogoURL) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 80, height: 80)
                                                    .clipShape(Circle())
                                            default:
                                                defaultLogoView
                                            }
                                        }
                                    } else {
                                        defaultLogoView
                                    }
                                    
                                    if isUploadingLogo {
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                            .frame(width: 80, height: 80)
                                        ProgressView()
                                            .tint(.white)
                                    }
                                }
                            }
                            .disabled(isUploadingLogo)
                            
                            Text(selectedImage != nil ? "Tap Save to upload" : "Tap to change logo")
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ModernDesign.Spacing.md)
                    }
                    
                    // Company Details
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.lg) {
                            ModernSectionHeader(title: "Company Details")
                            
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                Text("Company Name")
                                    .font(ModernDesign.Typography.caption)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                TextField("Enter company name", text: $companyName)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(ModernDesign.Colors.background)
                                    .cornerRadius(ModernDesign.Radius.medium)
                            }
                            
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                Text("Business Type")
                                    .font(ModernDesign.Typography.caption)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                Picker("Business Type", selection: $businessType) {
                                    ForEach(businessTypes, id: \.self) { type in
                                        Text(type).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(ModernDesign.Colors.background)
                                .cornerRadius(ModernDesign.Radius.medium)
                            }
                        }
                    }
                    
                    // Regional Settings
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.lg) {
                            ModernSectionHeader(title: "Regional Settings")
                            
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                Text("Currency")
                                    .font(ModernDesign.Typography.caption)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                Picker("Currency", selection: $defaultCurrency) {
                                    ForEach(currencies, id: \.self) { currency in
                                        Text(currency).tag(currency)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                Text("Working Hours")
                                    .font(ModernDesign.Typography.caption)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                HStack {
                                    Picker("Start", selection: $workingHoursStart) {
                                        ForEach(0..<24) { hour in
                                            Text("\(hour):00").tag(hour)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    
                                    Text("to")
                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                    
                                    Picker("End", selection: $workingHoursEnd) {
                                        ForEach(0..<24) { hour in
                                            Text("\(hour):00").tag(hour)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                .padding()
                                .background(ModernDesign.Colors.background)
                                .cornerRadius(ModernDesign.Radius.medium)
                            }
                        }
                    }
                    
                    // Save Button
                    Button(action: saveCompanyProfile) {
                        HStack {
                            if isUploadingLogo {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isUploadingLogo ? "Saving..." : "Save Changes")
                        }
                        .font(ModernDesign.Typography.label)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isUploadingLogo ? ModernDesign.Colors.primary.opacity(0.5) : ModernDesign.Colors.primary)
                        .cornerRadius(ModernDesign.Radius.large)
                    }
                    .disabled(isUploadingLogo)
                }
                .padding(ModernDesign.Spacing.lg)
            }
        }
        .navigationTitle("Company Profile")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Change Logo", isPresented: $showingPhotoOptions, titleVisibility: .visible) {
            Button("Take Photo") { showingCamera = true }
            Button("Choose from Library") { showingImagePicker = true }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .alert("Saved!", isPresented: $showingSaveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Company profile updated successfully.")
        }
    }
    
    private var defaultLogoView: some View {
        ZStack {
            Circle()
                .fill(ModernDesign.Colors.primary.opacity(0.1))
                .frame(width: 80, height: 80)
            Image(systemName: "building.2.fill")
                .font(.system(size: 32))
                .foregroundColor(ModernDesign.Colors.primary)
        }
    }
    
    private func saveCompanyProfile() {
        guard let userID = authService.currentUser?.id else { return }
        
        if let image = selectedImage {
            isUploadingLogo = true
            
            Task {
                do {
                    let logoURL = try await apiService.uploadImage(image, type: "company", id: userID)
                    
                    await MainActor.run {
                        companyLogoURL = logoURL
                        selectedImage = nil
                        isUploadingLogo = false
                        HapticsManager.shared.success()
                        showingSaveSuccess = true
                    }
                } catch {
                    print("❌ Company logo upload failed: \(error.localizedDescription)")
                    await MainActor.run {
                        isUploadingLogo = false
                        HapticsManager.shared.error()
                        // Show error to user
                        companyLogoURL = "" // Reset on failure
                    }
                }
            }
        } else {
            // Save other settings even if no image
            HapticsManager.shared.success()
            showingSaveSuccess = true
        }
    }
}

// MARK: - Roles & Permissions View
struct RolesPermissionsView: View {
    @State private var selectedRole = "Worker"
    
    // Local state (loaded from/saved to backend)
    @State private var canViewFinancials = false
    @State private var canUploadReceipts = true
    @State private var canApproveTimesheets = false
    @State private var canSeeAIInsights = false
    @State private var canViewAllJobs = false
    
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var isSaving = false
    
    private let apiService = APIService.shared
    
    let roles = ["Worker"]
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            if isLoading {
                ProgressView("Loading permissions...")
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        // Role Selector
                        ModernCard(shadow: true) {
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                                ModernSectionHeader(title: "Select Role to Configure")
                                
                                Picker("Role", selection: $selectedRole) {
                                    ForEach(roles, id: \.self) { role in
                                        Text(role).tag(role)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        
                        // Permissions
                        ModernCard(shadow: true) {
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "Permissions for \(selectedRole)")
                            
                            PermissionToggle(
                                icon: "dollarsign.circle.fill",
                                title: "View Job Financials",
                                subtitle: "Contract value, profit, payments",
                                isOn: $canViewFinancials
                            )
                            
                            Divider()
                            
                            PermissionToggle(
                                icon: "camera.fill",
                                title: "Upload Receipts",
                                subtitle: "Add new receipt documents",
                                isOn: $canUploadReceipts
                            )
                            
                            Divider()
                            
                            PermissionToggle(
                                icon: "checkmark.circle.fill",
                                title: "Approve Timesheets",
                                subtitle: "Review and approve hours",
                                isOn: $canApproveTimesheets
                            )
                            
                            Divider()
                            
                            PermissionToggle(
                                icon: "sparkles",
                                title: "View AI Insights",
                                subtitle: "Access business recommendations",
                                isOn: $canSeeAIInsights
                            )
                            
                            Divider()
                            
                            PermissionToggle(
                                icon: "briefcase.fill",
                                title: "View All Jobs",
                                subtitle: "See all jobs vs only assigned",
                                isOn: $canViewAllJobs
                            )
                        }
                    }
                    
                    // Info Card
                    ModernCard(backgroundColor: ModernDesign.Colors.info.opacity(0.1), shadow: false) {
                        HStack(alignment: .top, spacing: ModernDesign.Spacing.md) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(ModernDesign.Colors.info)
                            Text("Owner role has full access and cannot be modified. Changes apply to all workers with this role.")
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                        }
                    }
                    
                    // Save Button
                    Button(action: savePermissions) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isSaving ? "Saving..." : "Save Permissions")
                        }
                        .font(ModernDesign.Typography.label)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isSaving ? ModernDesign.Colors.primary.opacity(0.6) : ModernDesign.Colors.primary)
                        .cornerRadius(ModernDesign.Radius.large)
                    }
                    .disabled(isSaving)
                }
                .padding(ModernDesign.Spacing.lg)
            }
        }
        }
        .navigationTitle("Roles & Permissions")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadPermissions()
        }
        .alert("Saved", isPresented: $showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Permissions have been saved and will apply to all workers.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadPermissions() {
        isLoading = true
        Task {
            do {
                let permissions = try await apiService.getWorkerPermissions()
                await MainActor.run {
                    canViewFinancials = permissions.canViewFinancials
                    canUploadReceipts = permissions.canUploadReceipts
                    canApproveTimesheets = permissions.canApproveTimesheets
                    canSeeAIInsights = permissions.canSeeAIInsights
                    canViewAllJobs = permissions.canViewAllJobs
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    // Use defaults on error
                    isLoading = false
                }
            }
        }
    }
    
    private func savePermissions() {
        isSaving = true
        HapticsManager.shared.selection()
        
        Task {
            do {
                let permissions = WorkerPermissions(
                    canViewFinancials: canViewFinancials,
                    canUploadReceipts: canUploadReceipts,
                    canApproveTimesheets: canApproveTimesheets,
                    canSeeAIInsights: canSeeAIInsights,
                    canViewAllJobs: canViewAllJobs
                )
                try await apiService.saveWorkerPermissions(permissions)
                await MainActor.run {
                    isSaving = false
                    HapticsManager.shared.success()
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct PermissionToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: ModernDesign.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(ModernDesign.Colors.primary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ModernDesign.Typography.body)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    Text(subtitle)
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                }
            }
        }
        .tint(ModernDesign.Colors.primary)
    }
}

// MARK: - AI Automation Settings View
struct AIAutomationSettingsView: View {
    @AppStorage("aiMode") private var aiMode = "assist"
    @AppStorage("autoFillReceipts") private var autoFillReceipts = true
    @AppStorage("autoAssignReceipts") private var autoAssignReceipts = true
    @AppStorage("autoCalculateLabor") private var autoCalculateLabor = true
    @AppStorage("autoGenerateSummaries") private var autoGenerateSummaries = false
    @AppStorage("autoGenerateInsights") private var autoGenerateInsights = true
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    // AI Mode Selector
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.lg) {
                            ModernSectionHeader(title: "AI Automation Level")
                            
                            VStack(spacing: ModernDesign.Spacing.md) {
                                AIModeOption(
                                    mode: "manual",
                                    title: "Manual",
                                    description: "AI only suggests, never changes data",
                                    icon: "hand.raised.fill",
                                    isSelected: aiMode == "manual"
                                ) { aiMode = "manual" }
                                
                                AIModeOption(
                                    mode: "assist",
                                    title: "Assist",
                                    description: "AI auto-fills but requires approval",
                                    icon: "person.and.background.dotted",
                                    isSelected: aiMode == "assist"
                                ) { aiMode = "assist" }
                                
                                AIModeOption(
                                    mode: "autopilot",
                                    title: "Auto-Pilot",
                                    description: "AI applies changes automatically",
                                    icon: "cpu.fill",
                                    isSelected: aiMode == "autopilot"
                                ) { aiMode = "autopilot" }
                            }
                        }
                    }
                    
                    // Feature Toggles
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "AI Features")
                            
                            AIFeatureToggle(
                                icon: "doc.text.viewfinder",
                                title: "Auto-fill receipts from photos",
                                isOn: $autoFillReceipts
                            )
                            
                            Divider()
                            
                            AIFeatureToggle(
                                icon: "arrow.right.doc.on.clipboard",
                                title: "Auto-assign receipts to jobs",
                                isOn: $autoAssignReceipts
                            )
                            
                            Divider()
                            
                            AIFeatureToggle(
                                icon: "function",
                                title: "Auto-calculate labor costs",
                                isOn: $autoCalculateLabor
                            )
                            
                            Divider()
                            
                            AIFeatureToggle(
                                icon: "text.alignleft",
                                title: "Auto-generate job summaries",
                                isOn: $autoGenerateSummaries
                            )
                            
                            Divider()
                            
                            AIFeatureToggle(
                                icon: "lightbulb.fill",
                                title: "Auto-generate business insights",
                                isOn: $autoGenerateInsights
                            )
                        }
                    }
                }
                .padding(ModernDesign.Spacing.lg)
            }
        }
        .navigationTitle("AI Automation")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct AIModeOption: View {
    let mode: String
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.selection()
            action()
        }) {
            HStack(spacing: ModernDesign.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? ModernDesign.Colors.primary : ModernDesign.Colors.background)
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : ModernDesign.Colors.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ModernDesign.Typography.label)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    Text(description)
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ModernDesign.Colors.primary)
                        .font(.system(size: 24))
                }
            }
            .padding(ModernDesign.Spacing.md)
            .background(isSelected ? ModernDesign.Colors.primary.opacity(0.1) : ModernDesign.Colors.cardBackground)
            .cornerRadius(ModernDesign.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ModernDesign.Radius.medium)
                    .stroke(isSelected ? ModernDesign.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AIFeatureToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: ModernDesign.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(ModernDesign.Colors.primary)
                    .frame(width: 28)
                Text(title)
                    .font(ModernDesign.Typography.body)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
            }
        }
        .tint(ModernDesign.Colors.primary)
    }
}

// MARK: - AI Thresholds View
struct AIThresholdsView: View {
    @AppStorage("minConfidence") private var minConfidence = 85.0
    @AppStorage("flagLowConfidence") private var flagLowConfidence = true
    @AppStorage("flagUnusualHours") private var flagUnusualHours = true
    @AppStorage("maxDailyHours") private var maxDailyHours = 12.0
    @AppStorage("budgetAlertThreshold") private var budgetAlertThreshold = 75.0
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    // Confidence Threshold
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "AI Confidence")
                            
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
                                HStack {
                                    Text("Minimum confidence for auto-apply")
                                        .font(ModernDesign.Typography.body)
                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                    Spacer()
                                    Text("\(Int(minConfidence))%")
                                        .font(ModernDesign.Typography.label)
                                        .foregroundColor(ModernDesign.Colors.primary)
                                }
                                
                                Slider(value: $minConfidence, in: 50...100, step: 5)
                                    .tint(ModernDesign.Colors.primary)
                                
                                Text("Lower = more automation, Higher = more accuracy")
                                    .font(ModernDesign.Typography.caption)
                                    .foregroundColor(ModernDesign.Colors.textTertiary)
                            }
                            
                            Divider()
                            
                            Toggle(isOn: $flagLowConfidence) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Flag low-confidence items")
                                        .font(ModernDesign.Typography.body)
                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                    Text("Mark items that need manual review")
                                        .font(ModernDesign.Typography.caption)
                                        .foregroundColor(ModernDesign.Colors.textTertiary)
                                }
                            }
                            .tint(ModernDesign.Colors.primary)
                        }
                    }
                    
                    // Labor Alerts
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "Labor Monitoring")
                            
                            Toggle(isOn: $flagUnusualHours) {
                                Text("Flag unusual worker hours")
                                    .font(ModernDesign.Typography.body)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                            }
                            .tint(ModernDesign.Colors.primary)
                            
                            if flagUnusualHours {
                                VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
                                    HStack {
                                        Text("Max daily hours before alert")
                                            .font(ModernDesign.Typography.body)
                                            .foregroundColor(ModernDesign.Colors.textPrimary)
                                        Spacer()
                                        Text("\(Int(maxDailyHours))h")
                                            .font(ModernDesign.Typography.label)
                                            .foregroundColor(ModernDesign.Colors.primary)
                                    }
                                    
                                    Slider(value: $maxDailyHours, in: 6...16, step: 1)
                                        .tint(ModernDesign.Colors.primary)
                                }
                            }
                        }
                    }
                    
                    // Budget Alerts
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "Budget Monitoring")
                            
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
                                HStack {
                                    Text("Alert when job cost reaches")
                                        .font(ModernDesign.Typography.body)
                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                    Spacer()
                                    Text("\(Int(budgetAlertThreshold))%")
                                        .font(ModernDesign.Typography.label)
                                        .foregroundColor(ModernDesign.Colors.warning)
                                }
                                
                                Slider(value: $budgetAlertThreshold, in: 50...100, step: 5)
                                    .tint(ModernDesign.Colors.warning)
                                
                                Text("Percentage of contract value")
                                    .font(ModernDesign.Typography.caption)
                                    .foregroundColor(ModernDesign.Colors.textTertiary)
                            }
                        }
                    }
                }
                .padding(ModernDesign.Spacing.lg)
            }
        }
        .navigationTitle("AI Thresholds")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Data Retention View
struct DataRetentionView: View {
    @AppStorage("receiptRetention") private var receiptRetention = "forever"
    @AppStorage("tempImagesRetention") private var tempImagesRetention = 7
    
    let retentionOptions = [
        ("forever", "Keep Forever (Recommended)"),
        ("1year", "1 Year"),
        ("6months", "6 Months")
    ]
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    // Permanent Data
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "Receipts & Documents")
                            
                            ForEach(retentionOptions, id: \.0) { option in
                                RetentionOption(
                                    title: option.1,
                                    isSelected: receiptRetention == option.0
                                ) {
                                    receiptRetention = option.0
                                }
                            }
                        }
                    }
                    
                    // Temp Data
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "Temporary Files")
                            
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
                                Text("Failed AI uploads & temp images")
                                    .font(ModernDesign.Typography.body)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                                
                                Picker("Retention", selection: $tempImagesRetention) {
                                    Text("24 hours").tag(1)
                                    Text("7 days").tag(7)
                                    Text("30 days").tag(30)
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                    }
                    
                    // Info Card
                    ModernCard(backgroundColor: ModernDesign.Colors.warning.opacity(0.1), shadow: false) {
                        HStack(alignment: .top, spacing: ModernDesign.Spacing.md) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(ModernDesign.Colors.warning)
                            Text("Reducing retention period will delete older data. This cannot be undone.")
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                        }
                    }
                }
                .padding(ModernDesign.Spacing.lg)
            }
        }
        .navigationTitle("Data Retention")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct RetentionOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.selection()
            action()
        }) {
            HStack {
                Text(title)
                    .font(ModernDesign.Typography.body)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ModernDesign.Colors.primary)
                }
            }
            .padding(.vertical, ModernDesign.Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Export Data View
struct ExportDataView: View {
    @EnvironmentObject var authService: AuthService
    @State private var exportScope = "all"
    @State private var exportFormat = "csv"
    @State private var isExporting = false
    @State private var showExportSuccess = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let apiService = APIService.shared
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "Export Scope")
                            
                            Picker("Scope", selection: $exportScope) {
                                Text("All Data").tag("all")
                                Text("Jobs Only").tag("jobs")
                                Text("Receipts Only").tag("receipts")
                                Text("Timesheets Only").tag("timesheets")
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "Export Format")
                            
                            HStack(spacing: ModernDesign.Spacing.md) {
                                ExportFormatButton(icon: "doc.text.fill", format: "CSV", isSelected: exportFormat == "csv") {
                                    exportFormat = "csv"
                                }
                                ExportFormatButton(icon: "curlybraces", format: "JSON", isSelected: exportFormat == "json") {
                                    exportFormat = "json"
                                }
                            }
                        }
                    }
                    
                    Button(action: exportData) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text(isExporting ? "Exporting..." : "Export Data")
                        }
                        .font(ModernDesign.Typography.label)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ModernDesign.Colors.primary)
                        .cornerRadius(ModernDesign.Radius.large)
                    }
                    .disabled(isExporting)
                }
                .padding(ModernDesign.Spacing.lg)
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func exportData() {
        guard authService.currentUser?.id != nil else {
            errorMessage = "Not signed in"
            showError = true
            return
        }
        
        isExporting = true
        
        Task {
            do {
                var csvContent = ""
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                
                // Fetch data based on scope
                if exportScope == "all" || exportScope == "jobs" {
                    csvContent += "=== JOBS ===\n"
                    csvContent += "Job Name,Client,Status,Project Value,Amount Paid,Created\n"
                    
                    let jobs = try await apiService.fetchJobs()
                    for job in jobs {
                        let created = dateFormatter.string(from: job.createdAt)
                        csvContent += "\"\(job.jobName)\",\"\(job.clientName)\",\(job.status.rawValue),\(job.projectValue),\(job.amountPaid),\(created)\n"
                    }
                    csvContent += "\n"
                }
                
                if exportScope == "all" || exportScope == "receipts" {
                    csvContent += "=== RECEIPTS ===\n"
                    csvContent += "Vendor,Amount,Category,Date,Notes\n"
                    
                    let receipts = try await apiService.fetchReceipts()
                    for receipt in receipts {
                        let date = dateFormatter.string(from: receipt.date ?? Date())
                        let category = receipt.category ?? "other"
                        csvContent += "\"\(receipt.vendor ?? "")\",\(receipt.amount ?? 0),\(category),\(date),\"\(receipt.notes ?? "")\"\n"
                    }
                    csvContent += "\n"
                }
                
                if exportScope == "all" || exportScope == "timesheets" {
                    csvContent += "=== TIMESHEETS ===\n"
                    csvContent += "Worker,Job ID,Clock In,Clock Out,Hours,Notes\n"
                    
                    let timesheets = try await apiService.fetchTimesheets()
                    for timesheet in timesheets {
                        let clockIn = dateFormatter.string(from: timesheet.clockIn ?? Date())
                        let clockOut = timesheet.clockOut != nil ? dateFormatter.string(from: timesheet.clockOut!) : "Active"
                        csvContent += "\"\(timesheet.userID ?? "")\",\(timesheet.jobID ?? ""),\(clockIn),\(clockOut),\(timesheet.hours ?? 0),\"\(timesheet.notes ?? "")\"\n"
                    }
                }
                
                // Save to file
                let fileName = "siteledger_export_\(Date().timeIntervalSince1970).\(exportFormat)"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                
                if exportFormat == "json" {
                    // Convert CSV to simple JSON
                    let jsonData = ["export_date": Date().description, "data": csvContent]
                    let jsonString = try JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted)
                    try jsonString.write(to: tempURL)
                } else {
                    try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
                }
                
                await MainActor.run {
                    isExporting = false
                    exportURL = tempURL
                    showShareSheet = true
                }
                
            } catch {
                await MainActor.run {
                    isExporting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// Share Sheet for iOS
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ExportFormatButton: View {
    let icon: String
    let format: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.selection()
            action()
        }) {
            VStack(spacing: ModernDesign.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(format)
                    .font(ModernDesign.Typography.caption)
            }
            .foregroundColor(isSelected ? .white : ModernDesign.Colors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ModernDesign.Spacing.md)
            .background(isSelected ? ModernDesign.Colors.primary : ModernDesign.Colors.primary.opacity(0.1))
            .cornerRadius(ModernDesign.Radius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Smart Notifications View
struct SmartNotificationsView: View {
    @AppStorage("notifyBudgetThreshold") private var notifyBudgetThreshold = true
    @AppStorage("notifyPaymentBehind") private var notifyPaymentBehind = true
    @AppStorage("notifyWorkerHours") private var notifyWorkerHours = true
    @AppStorage("notifyNewInsight") private var notifyNewInsight = true
    @AppStorage("notifyReceiptReview") private var notifyReceiptReview = true
    @AppStorage("notifyDocExpiry") private var notifyDocExpiry = true
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "Smart Alert Rules")
                            
                            SmartNotificationToggle(
                                icon: "chart.line.downtrend.xyaxis",
                                title: "Budget threshold reached",
                                subtitle: "When job cost passes 75% of contract",
                                color: .orange,
                                isOn: $notifyBudgetThreshold
                            )
                            
                            Divider()
                            
                            SmartNotificationToggle(
                                icon: "dollarsign.circle",
                                title: "Payment behind schedule",
                                subtitle: "When client payments are overdue",
                                color: .red,
                                isOn: $notifyPaymentBehind
                            )
                            
                            Divider()
                            
                            SmartNotificationToggle(
                                icon: "clock.badge.exclamationmark",
                                title: "Unusual worker hours",
                                subtitle: "When daily hours exceed limit",
                                color: .purple,
                                isOn: $notifyWorkerHours
                            )
                            
                            Divider()
                            
                            SmartNotificationToggle(
                                icon: "sparkles",
                                title: "New AI insight",
                                subtitle: "When AI generates recommendations",
                                color: ModernDesign.Colors.primary,
                                isOn: $notifyNewInsight
                            )
                            
                            Divider()
                            
                            SmartNotificationToggle(
                                icon: "doc.text.magnifyingglass",
                                title: "Receipt needs review",
                                subtitle: "When AI confidence is low",
                                color: .yellow,
                                isOn: $notifyReceiptReview
                            )
                            
                            Divider()
                            
                            SmartNotificationToggle(
                                icon: "calendar.badge.exclamationmark",
                                title: "Document expiring",
                                subtitle: "Permits, licenses, contracts",
                                color: .teal,
                                isOn: $notifyDocExpiry
                            )
                        }
                    }
                }
                .padding(ModernDesign.Spacing.lg)
            }
        }
        .navigationTitle("Smart Notifications")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct SmartNotificationToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: ModernDesign.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ModernDesign.Typography.body)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    Text(subtitle)
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                }
            }
        }
        .tint(ModernDesign.Colors.primary)
    }
}

// MARK: - Appearance Settings View
struct AppearanceSettingsView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("defaultTab") private var defaultTab = 0
    @AppStorage("defaultJobFilter") private var defaultJobFilter = "active"
    
    private var isWorker: Bool {
        authService.currentUser?.role == .worker
    }
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    // Theme
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "Theme")
                            
                            Picker("Theme", selection: $appTheme) {
                                Text("Light").tag("light")
                                Text("Dark").tag("dark")
                                Text("System").tag("system")
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    
                    // Home Behavior - Different options for Owner vs Worker
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "Start Screen")
                            
                            if isWorker {
                                // Worker tabs: My Jobs (0), Clock (1), Hours (2), More (3)
                                Picker("Default Tab", selection: $defaultTab) {
                                    Text("My Jobs").tag(0)
                                    Text("Clock").tag(1)
                                    Text("Hours").tag(2)
                                }
                                .pickerStyle(.segmented)
                            } else {
                                // Owner tabs: Dashboard (0), Jobs (1), Receipts (2), Documents (3), More (4)
                                Picker("Default Tab", selection: $defaultTab) {
                                    Text("Dashboard").tag(0)
                                    Text("Jobs").tag(1)
                                    Text("Receipts").tag(2)
                                    Text("Documents").tag(3)
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                    }
                    
                    // Default Filters
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "Default Filters")
                            
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                Text("Job Status Filter")
                                    .font(ModernDesign.Typography.caption)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                Picker("Job Filter", selection: $defaultJobFilter) {
                                    Text("Active Only").tag("active")
                                    Text("All Jobs").tag("all")
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                    }
                }
                .padding(ModernDesign.Spacing.lg)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Integrations View (Coming Soon)
struct IntegrationsView: View {
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            VStack(spacing: ModernDesign.Spacing.xl) {
                Spacer()
                
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(ModernDesign.Colors.primary.opacity(0.3))
                
                Text("Coming Soon")
                    .font(ModernDesign.Typography.title1)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
                
                Text("Accounting integrations with QuickBooks, Xero, and more are on the way.")
                    .font(ModernDesign.Typography.body)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ModernDesign.Spacing.xl)
                
                Spacer()
            }
        }
        .navigationTitle("Integrations")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Calendar Integration View (Coming Soon)
struct CalendarIntegrationView: View {
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            VStack(spacing: ModernDesign.Spacing.xl) {
                Spacer()
                
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 80))
                    .foregroundColor(ModernDesign.Colors.primary.opacity(0.3))
                
                Text("Coming Soon")
                    .font(ModernDesign.Typography.title1)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
                
                Text("Sync jobs and deadlines with Google Calendar and Apple Calendar.")
                    .font(ModernDesign.Typography.body)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ModernDesign.Spacing.xl)
                
                Spacer()
            }
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.large)
    }
}
