import SwiftUI
import PhotosUI

struct AddReceiptView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = ReceiptsViewModel()
    @StateObject private var jobsViewModel = JobsViewModel()
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var amount = ""
    @State private var vendor = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var selectedJob: Job?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // AI Processing states
    @State private var isProcessingImage = false
    @State private var aiConfidence: Double = 0.0
    @State private var aiFlags: [String] = []
    @State private var duplicateReceipts: [(receipt: Receipt, similarity: Double)] = []
    @State private var showDuplicateWarning = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                        // Header
                        ScreenHeader(
                            title: "Add Receipt",
                            subtitle: "Capture receipt details and attach proof",
                            action: nil,
                            actionIcon: nil
                        )
                        
                        VStack(spacing: DesignSystem.Spacing.cardSpacing) {
                            // Photo Section
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                Text("Receipt Photo")
                                    .font(DesignSystem.TextStyle.bodyBold)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                if let image = selectedImage {
                                    VStack(spacing: DesignSystem.Spacing.small) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 200)
                                            .cornerRadius(AppTheme.cornerRadius)
                                            .overlay(
                                                Button(action: {
                                                    selectedImage = nil
                                                    isProcessingImage = false
                                                    aiConfidence = 0.0
                                                    aiFlags = []
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(.white)
                                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                                }
                                                .padding(DesignSystem.Spacing.medium),
                                                alignment: .topTrailing
                                            )
                                        
                                        // AI Processing Status
                                        if isProcessingImage {
                                            HStack(spacing: DesignSystem.Spacing.small) {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                Text("Processing with AI...")
                                                    .font(DesignSystem.TextStyle.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                                Spacer()
                                            }
                                            .padding(DesignSystem.Spacing.small)
                                            .background(AppTheme.accentColor.opacity(0.1))
                                            .cornerRadius(AppTheme.smallCornerRadius)
                                        } else if aiConfidence > 0 {
                                            VStack(spacing: DesignSystem.Spacing.small) {
                                                // Confidence Score
                                                HStack(spacing: DesignSystem.Spacing.small) {
                                                    Image(systemName: aiConfidence >= 0.8 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                                        .font(DesignSystem.TextStyle.caption)
                                                        .foregroundColor(aiConfidence >= 0.8 ? AppTheme.successColor : AppTheme.warningColor)
                                                    
                                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                                                        Text("AI Confidence")
                                                            .font(DesignSystem.TextStyle.tiny)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                                        Text(String(format: "%.0f%%", aiConfidence * 100))
                                                            .font(DesignSystem.TextStyle.captionBold)
                                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    if !aiFlags.isEmpty {
                                                        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.tiny) {
                                                            Text("\(aiFlags.count) Flag(s)")
                                                                .font(DesignSystem.TextStyle.tiny)
                                                                .fontWeight(.medium)
                                                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                                            Text("Review")
                                                                .font(DesignSystem.TextStyle.tiny)
                                                                .fontWeight(.semibold)
                                                                .foregroundColor(AppTheme.warningColor)
                                                        }
                                                    }
                                                }
                                                .padding(DesignSystem.Spacing.small)
                                                .background(AppTheme.cardBackground)
                                                .cornerRadius(AppTheme.smallCornerRadius)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                                                        .stroke(AppTheme.textSecondary.opacity(0.1), lineWidth: 1)
                                                )
                                                
                                                // AI Flags Display
                                                if !aiFlags.isEmpty {
                                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                                                        Text("Detected Issues")
                                                            .font(DesignSystem.TextStyle.tiny)
                                                            .fontWeight(.semibold)
                                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                                        
                                                        ScrollView(.horizontal, showsIndicators: false) {
                                                            HStack(spacing: DesignSystem.Spacing.small) {
                                                                ForEach(aiFlags, id: \.self) { flag in
                                                                    AIFlagBadge(flag: flag)
                                                                }
                                                            }
                                                        }
                                                    }
                                                    .padding(DesignSystem.Spacing.small)
                                                    .background(AppTheme.warningColor.opacity(0.05))
                                                    .cornerRadius(AppTheme.smallCornerRadius)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                                                            .stroke(AppTheme.warningColor.opacity(0.2), lineWidth: 1)
                                                    )
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    VStack(spacing: DesignSystem.Spacing.medium) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(AppTheme.primaryColor)
                                        
                                        Text("No photo yet")
                                            .font(DesignSystem.TextStyle.bodySecondary)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                        
                                        HStack(spacing: DesignSystem.Spacing.medium) {
                                            SecondaryButton(title: "Take Photo") {
                                                HapticsManager.shared.light()
                                                showingCamera = true
                                            }
                                            SecondaryButton(title: "Choose Photo") {
                                                HapticsManager.shared.light()
                                                showingImagePicker = true
                                            }
                                        }
                                    }
                                    .frame(height: 180)
                                    .frame(maxWidth: .infinity)
                                    .background(AppTheme.primaryColor.opacity(0.08))
                                    .cornerRadius(AppTheme.cornerRadius)
                                }
                            }
                            .padding(DesignSystem.Spacing.cardPadding)
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
                            
                            // Receipt Details Section
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                Text("Receipt Information")
                                    .font(DesignSystem.TextStyle.bodyBold)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                CurrencyField(label: "Amount *", amount: $amount)
                                CustomTextField(placeholder: "Vendor Name *", text: $vendor)
                                
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                                    Text("Date")
                                        .font(DesignSystem.TextStyle.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    DatePicker("", selection: $date, displayedComponents: .date)
                                        .labelsHidden()
                                }
                            }
                            .padding(DesignSystem.Spacing.cardPadding)
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
                            
                            // Job Assignment Section
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                Text("Job Assignment")
                                    .font(DesignSystem.TextStyle.bodyBold)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Menu {
                                    Button("None") {
                                        selectedJob = nil
                                    }
                                    ForEach(jobsViewModel.jobs) { job in
                                        Button(job.jobName) {
                                            selectedJob = job
                                        }
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                                            Text("Assign to Job")
                                                .font(DesignSystem.TextStyle.caption)
                                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                            Text(selectedJob?.jobName ?? "Select Job")
                                                .font(DesignSystem.TextStyle.bodySecondary)
                                                .foregroundColor(selectedJob == nil ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(AppTheme.primaryColor)
                                    }
                                    .padding(DesignSystem.Spacing.cardPadding)
                                    .background(AppTheme.backgroundColor)
                                    .cornerRadius(AppTheme.cornerRadius)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                            .stroke(AppTheme.borderColor, lineWidth: 1)
                                    )
                                }
                            }
                            .padding(DesignSystem.Spacing.cardPadding)
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
                            
                            // Notes Section
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                Text("Additional Notes")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                TextEditor(text: $notes)
                                    .frame(height: 100)
                                    .padding(DesignSystem.Spacing.small)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(AppTheme.smallCornerRadius)
                                    .font(.system(size: 14))
                            }
                            .padding(DesignSystem.Spacing.cardPadding)
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
                            
                            // Error Message
                            if showError {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(AppTheme.errorColor)
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.errorColor)
                                    Spacer()
                                }
                                .padding(DesignSystem.Spacing.cardPadding)
                                .background(AppTheme.errorColor.opacity(0.1))
                                .cornerRadius(AppTheme.cornerRadius)
                            }
                            
                            // Add Button
                            PrimaryButton(title: "Add Receipt", action: addReceipt, isLoading: isLoading)
                                .padding(.top, DesignSystem.Spacing.medium)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                    }
                    .padding(.top, DesignSystem.Spacing.cardPadding)
                    .padding(.bottom, DesignSystem.Spacing.huge)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Cancel")
                        }
                        .foregroundColor(AppTheme.primaryColor)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .onChange(of: selectedImage) { _, newValue in
                if let image = newValue {
                    print("📸 IMAGE FOUND - PROCESSING NOW")
                    print("🔄 Calling AIService.processReceiptImage...")
                    // Trigger AI image processing
                    processImageWithAI(image)
                }
            }
            .onAppear {
                if let userID = authService.currentUser?.id {
                    jobsViewModel.loadJobs(userID: userID)
                    viewModel.loadReceipts(userID: userID)
                }
            }
            .alert("Possible Duplicate Receipt", isPresented: $showDuplicateWarning) {
                Button("Continue Anyway", role: .none) {
                    showDuplicateWarning = false
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            } message: {
                if !duplicateReceipts.isEmpty {
                    Text(AIService.shared.generateDuplicateAlertMessage(for: Receipt(
                        ownerID: authService.currentUser?.id ?? "",
                        amount: Double(amount) ?? 0,
                        vendor: vendor,
                        date: date,
                        notes: notes,
                        createdAt: Date(),
                        aiProcessed: true
                    ), duplicates: duplicateReceipts))
                } else {
                    Text("This receipt may be a duplicate.")
                }
            }
        }
    }

    /// Process receipt image with AI to extract vendor, amount, and date
    private func processImageWithAI(_ image: UIImage) {
        print("🤖 processImageWithAI() called")
        isProcessingImage = true
        aiConfidence = 0.0
        aiFlags = []
        duplicateReceipts = []
        
        Task {
            do {
                print("⏳ Awaiting AIService.processReceiptImage...")
                let receiptData = try await AIService.shared.processReceiptImage(image)
                print("✅ GOT OCR RESULT: Vendor=\(receiptData.vendor), Amount=\(receiptData.amount)")
                
                await MainActor.run {
                    print("📝 Auto-filling form fields...")
                    // Auto-fill form fields with AI-extracted data
                    vendor = receiptData.vendor
                    amount = String(format: "%.2f", receiptData.amount)
                    date = receiptData.date
                    
                    print("✅ Form filled: Vendor=\(vendor), Amount=\(amount)")
                    
                    // Use the confidence from OCR extraction
                    aiConfidence = receiptData.confidence
                    
                    // Analyze for flags
                    if vendor == "Unknown" || vendor.isEmpty {
                        aiFlags.append("missing_vendor")
                    }
                    if amount == "0.00" || amount.isEmpty {
                        aiFlags.append("missing_amount")
                    }
                    
                    // Check for refund
                    let tempReceipt = Receipt(
                        ownerID: authService.currentUser?.id ?? "",
                        amount: receiptData.amount,
                        vendor: receiptData.vendor,
                        date: receiptData.date,
                        notes: notes,
                        createdAt: Date(),
                        aiProcessed: true
                    )
                    
                    if AIService.shared.isLikelyRefund(tempReceipt) {
                        aiFlags.append("possible_refund")
                    }
                    
                    // Check for duplicates
                    checkForDuplicates()
                    
                    isProcessingImage = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "AI processing failed: \(error.localizedDescription)"
                    showError = true
                    isProcessingImage = false
                }
            }
        }
    }
    
    /// Check for duplicate receipts in existing receipts
    private func checkForDuplicates() {
        guard let userID = authService.currentUser?.id,
              let amountDouble = Double(amount) else { return }
        
        let tempReceipt = Receipt(
            ownerID: userID,
            jobID: selectedJob?.id,
            amount: amountDouble,
            vendor: vendor,
            date: date,
            notes: notes,
            createdAt: Date(),
            aiProcessed: true
        )
        
        duplicateReceipts = AIService.shared.detectDuplicates(tempReceipt, in: viewModel.receipts)
        
        if !duplicateReceipts.isEmpty {
            aiFlags.append("possible_duplicate")
            showDuplicateWarning = true
        }
    }
    
    private func addReceipt() {
        guard let amountDouble = Double(amount), amountDouble > 0 else {
            HapticsManager.shared.error()
            errorMessage = "Please enter a valid amount"
            showError = true
            return
        }
        
        guard !vendor.isEmpty else {
            HapticsManager.shared.error()
            errorMessage = "Please enter a vendor name"
            showError = true
            return
        }
        
        guard let userID = authService.currentUser?.id else { return }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                var imageURL: String?
                
                // Upload image if present
                if let image = selectedImage {
                    let receiptID = UUID().uuidString
                    imageURL = try await viewModel.uploadReceiptImage(image, receiptID: receiptID)
                }
                
                // Auto-categorize receipt with AI
                let (suggestedCategory, categoryConfidence) = AIService.shared.categorizeReceiptDetailed(vendor: vendor, amount: amountDouble)
                
                // IMPORTANT: Use job's ownerID, not the current user's ID
                // This allows workers to submit receipts that appear on the owner's account
                let receiptOwnerID = selectedJob?.ownerID ?? userID
                
                let receipt = Receipt(
                    ownerID: receiptOwnerID,
                    jobID: selectedJob?.id,
                    amount: amountDouble,
                    vendor: vendor,
                    category: suggestedCategory,
                    date: date,
                    imageURL: imageURL,
                    notes: notes,
                    createdAt: Date(),
                    aiProcessed: true,
                    aiConfidence: aiConfidence > 0 ? aiConfidence : categoryConfidence,
                    aiFlags: aiFlags.isEmpty ? nil : aiFlags,
                    aiSuggestedCategory: suggestedCategory
                )
                
                try await viewModel.createReceipt(receipt)
                
                await MainActor.run {
                    HapticsManager.shared.success()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    HapticsManager.shared.error()
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - AI Flag Badge Component

struct AIFlagBadge: View {
    let flag: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 10, weight: .semibold))
            Text(displayText)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(flagColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(flagColor.opacity(0.15))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(flagColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var iconName: String {
        switch flag {
        case "possible_duplicate":
            return "doc.on.doc"
        case "unusually_high":
            return "arrow.up.circle"
        case "missing_vendor":
            return "questionmark.circle"
        case "missing_amount":
            return "dollarsign.circle"
        case "possible_refund":
            return "arrow.counterclockwise"
        default:
            return "exclamationmark.triangle"
        }
    }
    
    private var displayText: String {
        switch flag {
        case "possible_duplicate":
            return "Duplicate"
        case "unusually_high":
            return "High Amount"
        case "missing_vendor":
            return "No Vendor"
        case "missing_amount":
            return "No Amount"
        case "possible_refund":
            return "Refund"
        default:
            return flag.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    private var flagColor: Color {
        switch flag {
        case "possible_duplicate":
            return Color.orange
        case "unusually_high":
            return Color.red
        case "missing_vendor", "missing_amount":
            return Color.yellow.opacity(0.8)
        case "possible_refund":
            return Color.blue
        default:
            return Color.gray
        }
    }
}