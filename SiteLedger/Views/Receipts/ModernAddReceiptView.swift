import SwiftUI
import PhotosUI

struct ModernAddReceiptView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = ReceiptsViewModel()
    @StateObject private var jobsViewModel = JobsViewModel()
    
    // Optional: Pre-selected job (when adding from job detail)
    var preSelectedJob: Job? = nil
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingScanner = false // NEW
    @State private var amount = ""
    @State private var vendor = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var selectedJob: Job?
    @State private var selectedCategory: Receipt.ReceiptCategory = .other
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // AI Processing states
    @State private var isProcessingImage = false
    @State private var aiConfidence: Double = 0.0
    @State private var aiFlags: [String] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        // Header
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                            Text("Add Receipt")
                                .font(ModernDesign.Typography.displayMedium)
                                .foregroundColor(ModernDesign.Colors.textPrimary)
                            
                            Text("Capture receipt details and attach proof")
                                .font(ModernDesign.Typography.body)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Photo Section
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(title: "Receipt Photo")
                                
                                if let image = selectedImage {
                                    VStack(spacing: ModernDesign.Spacing.md) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxHeight: 200)
                                                .cornerRadius(ModernDesign.Radius.medium)
                                            
                                            Button(action: {
                                                HapticsManager.shared.light()
                                                selectedImage = nil
                                                isProcessingImage = false
                                                aiConfidence = 0.0
                                                aiFlags = []
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.white)
                                                    .shadow(radius: 2)
                                            }
                                            .padding(ModernDesign.Spacing.sm)
                                        }
                                        
                                        // AI Processing Status
                                        if isProcessingImage {
                                            HStack(spacing: ModernDesign.Spacing.sm) {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                Text("Processing with AI...")
                                                    .font(ModernDesign.Typography.labelSmall)
                                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                                Spacer()
                                            }
                                            .padding(ModernDesign.Spacing.md)
                                            .background(ModernDesign.Colors.info.opacity(0.1))
                                            .cornerRadius(ModernDesign.Radius.small)
                                        } else if aiConfidence > 0 {
                                            HStack(spacing: ModernDesign.Spacing.sm) {
                                                Image(systemName: aiConfidence >= 0.8 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                                    .foregroundColor(aiConfidence >= 0.8 ? ModernDesign.Colors.success : ModernDesign.Colors.warning)
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("AI Confidence")
                                                        .font(ModernDesign.Typography.captionSmall)
                                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                                    Text(String(format: "%.0f%%", aiConfidence * 100))
                                                        .font(ModernDesign.Typography.labelSmall)
                                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                                }
                                                
                                                Spacer()
                                                
                                                if !aiFlags.isEmpty {
                                                    Text("\(aiFlags.count) flag(s)")
                                                        .font(ModernDesign.Typography.captionSmall)
                                                        .foregroundColor(ModernDesign.Colors.warning)
                                                }
                                            }
                                            .padding(ModernDesign.Spacing.md)
                                            .background(aiConfidence >= 0.8 ? ModernDesign.Colors.success.opacity(0.1) : ModernDesign.Colors.warning.opacity(0.1))
                                            .cornerRadius(ModernDesign.Radius.small)
                                        }
                                    }
                                } else {
                                    VStack(spacing: ModernDesign.Spacing.lg) {
                                        ZStack {
                                            Circle()
                                                .fill(ModernDesign.Colors.primary.opacity(0.1))
                                                .frame(width: 80, height: 80)
                                            
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 32))
                                                .foregroundColor(ModernDesign.Colors.primary)
                                        }
                                        
                                        Text("No photo yet")
                                            .font(ModernDesign.Typography.body)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                        
                                        HStack(spacing: ModernDesign.Spacing.md) {
                                                .background(ModernDesign.Colors.primary.opacity(0.1))
                                                .cornerRadius(ModernDesign.Radius.medium)
                                            }
                                            
                                            Button(action: {
                                                HapticsManager.shared.light()
                                                showingScanner = true
                                            }) {
                                                HStack(spacing: ModernDesign.Spacing.xs) {
                                                    Image(systemName: "doc.viewfinder")
                                                    Text("Scan")
                                                }
                                                .font(ModernDesign.Typography.label)
                                                .foregroundColor(ModernDesign.Colors.primary)
                                                .padding(.horizontal, ModernDesign.Spacing.lg)
                                                .padding(.vertical, ModernDesign.Spacing.md)
                                                .background(ModernDesign.Colors.primary.opacity(0.1))
                                                .cornerRadius(ModernDesign.Radius.medium)
                                            }
                                            
                                            Button(action: {
                                                HapticsManager.shared.light()
                                                showingImagePicker = true
                                            }) {
                                                HStack(spacing: ModernDesign.Spacing.xs) {
                                                    Image(systemName: "photo")
                                                    Text("Gallery")
                                                }
                                                .font(ModernDesign.Typography.label)
                                                .foregroundColor(ModernDesign.Colors.primary)
                                                .padding(.horizontal, ModernDesign.Spacing.lg)
                                                .padding(.vertical, ModernDesign.Spacing.md)
                                                .background(ModernDesign.Colors.primary.opacity(0.1))
                                                .cornerRadius(ModernDesign.Radius.medium)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, ModernDesign.Spacing.xl)
                                    .background(ModernDesign.Colors.background)
                                    .cornerRadius(ModernDesign.Radius.medium)
                                }
                            }
                        }
                        
                        // Receipt Details
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(title: "Receipt Details")
                                
                                VStack(spacing: ModernDesign.Spacing.md) {
                                    // Amount
                                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                        Text("Amount")
                                            .font(ModernDesign.Typography.labelSmall)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                        
                                        HStack(spacing: ModernDesign.Spacing.sm) {
                                            Image(systemName: "dollarsign.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(ModernDesign.Colors.primary)
                                            
                                            TextField("0.00", text: $amount)
                                                .font(ModernDesign.Typography.title3)
                                                .keyboardType(.decimalPad)
                                        }
                                        .padding(ModernDesign.Spacing.md)
                                        .background(ModernDesign.Colors.background)
                                        .cornerRadius(ModernDesign.Radius.medium)
                                    }
                                    
                                    // Vendor
                                    ModernTextField(
                                        placeholder: "Vendor Name",
                                        text: $vendor,
                                        icon: "building.2.fill"
                                    )
                                    
                                    // Date
                                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                        Text("Date")
                                            .font(ModernDesign.Typography.labelSmall)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                        
                                        DatePicker("", selection: $date, displayedComponents: .date)
                                            .labelsHidden()
                                            .tint(ModernDesign.Colors.primary)
                                    }
                                }
                            }
                        }
                        
                        // Job Assignment - Only show if no job was pre-selected
                        if preSelectedJob == nil {
                            ModernCard(shadow: true) {
                                VStack(spacing: ModernDesign.Spacing.lg) {
                                    ModernSectionHeader(
                                        title: "Job Assignment",
                                        subtitle: "Optional"
                                    )
                                    
                                    Menu {
                                        Button("None") {
                                            HapticsManager.shared.selection()
                                            selectedJob = nil
                                        }
                                        ForEach(jobsViewModel.jobs) { job in
                                            Button(job.jobName) {
                                                HapticsManager.shared.selection()
                                                selectedJob = job
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "briefcase.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(ModernDesign.Colors.textTertiary)
                                            
                                            Text(selectedJob?.jobName ?? "Select Job")
                                                .font(ModernDesign.Typography.body)
                                                .foregroundColor(selectedJob == nil ? ModernDesign.Colors.textTertiary : ModernDesign.Colors.textPrimary)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(ModernDesign.Colors.textTertiary)
                                        }
                                        .padding(ModernDesign.Spacing.md)
                                        .background(ModernDesign.Colors.background)
                                        .cornerRadius(ModernDesign.Radius.medium)
                                    }
                                }
                            }
                        } else {
                            // Show the pre-selected job as read-only info
                            ModernCard(shadow: true) {
                                VStack(spacing: ModernDesign.Spacing.lg) {
                                    ModernSectionHeader(
                                        title: "Job",
                                        subtitle: "Adding receipt to this job"
                                    )
                                    
                                    HStack {
                                        Image(systemName: "briefcase.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(ModernDesign.Colors.primary)
                                        
                                        Text(preSelectedJob?.jobName ?? "")
                                            .font(ModernDesign.Typography.body)
                                            .foregroundColor(ModernDesign.Colors.textPrimary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(ModernDesign.Colors.success)
                                    }
                                    .padding(ModernDesign.Spacing.md)
                                    .background(ModernDesign.Colors.success.opacity(0.1))
                                    .cornerRadius(ModernDesign.Radius.medium)
                                }
                            }
                        }
                        
                        // Category Selection
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Category",
                                    subtitle: "AI suggested or select manually"
                                )
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: ModernDesign.Spacing.md) {
                                    ForEach(Receipt.ReceiptCategory.allCases, id: \.self) { cat in
                                        Button(action: {
                                            HapticsManager.shared.selection()
                                            selectedCategory = cat
                                        }) {
                                            VStack(spacing: ModernDesign.Spacing.xs) {
                                                Image(systemName: cat.icon)
                                                    .font(.system(size: 20))
                                                Text(cat.displayName)
                                                    .font(ModernDesign.Typography.captionSmall)
                                            }
                                            .foregroundColor(selectedCategory == cat ? .white : ModernDesign.Colors.primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, ModernDesign.Spacing.md)
                                            .background(selectedCategory == cat ? ModernDesign.Colors.primary : ModernDesign.Colors.primary.opacity(0.1))
                                            .cornerRadius(ModernDesign.Radius.medium)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        
                        // Notes
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Notes",
                                    subtitle: "Optional"
                                )
                                
                                TextEditor(text: $notes)
                                    .frame(height: 100)
                                    .padding(ModernDesign.Spacing.sm)
                                    .background(ModernDesign.Colors.background)
                                    .cornerRadius(ModernDesign.Radius.small)
                                    .font(ModernDesign.Typography.body)
                            }
                        }
                        
                        // Error Message
                        if showError {
                            HStack(spacing: ModernDesign.Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(ModernDesign.Colors.error)
                                Text(errorMessage)
                                    .font(ModernDesign.Typography.body)
                                    .foregroundColor(ModernDesign.Colors.error)
                                Spacer()
                            }
                            .padding(ModernDesign.Spacing.md)
                            .background(ModernDesign.Colors.error.opacity(0.1))
                            .cornerRadius(ModernDesign.Radius.medium)
                        }
                        
                        // Add Button
                        ModernButton(
                            title: "Add Receipt",
                            icon: "checkmark.circle.fill",
                            style: .primary,
                            size: .large,
                            action: addReceipt,
                            isLoading: isLoading
                        )
                        .padding(.top, ModernDesign.Spacing.sm)
                    }
                    .padding(ModernDesign.Spacing.lg)
                    .padding(.bottom, ModernDesign.Spacing.xxxl)
                }
            }
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
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingScanner) {
                DocumentScannerView(image: $selectedImage)
            }
            .onChange(of: selectedImage) { _, newValue in
                if let image = newValue {
                    processImageWithAI(image)
                }
            }
            .onAppear {
                // If a job was pre-selected, use it
                if let job = preSelectedJob {
                    selectedJob = job
                }
                
                if let userID = authService.currentUser?.id {
                    jobsViewModel.loadJobs(userID: userID)
                    viewModel.loadReceipts(userID: userID)
                }
            }
        }
    }
    
    private func processImageWithAI(_ image: UIImage) {
        isProcessingImage = true
        aiConfidence = 0.0
        aiFlags = []
        
        Task {
            do {
                let receiptData = try await AIService.shared.processReceiptImage(image)
                
                await MainActor.run {
                    vendor = receiptData.vendor
                    amount = String(format: "%.2f", receiptData.amount)
                    date = receiptData.date
                    
                    // Use the confidence from OCR extraction
                    aiConfidence = receiptData.confidence
                    
                    // Map AI category suggestion to enum
                    switch receiptData.category.lowercased() {
                    case "materials":
                        selectedCategory = .materials
                    case "fuel", "gas/fuel", "gas":
                        selectedCategory = .gasFuel
                    case "tools", "equipment":
                        selectedCategory = .equipment
                    default:
                        selectedCategory = .other
                    }
                    
                    if vendor == "Unknown" || vendor.isEmpty {
                        aiFlags.append("missing_vendor")
                    }
                    if amount == "0.00" || amount.isEmpty {
                        aiFlags.append("missing_amount")
                    }
                    
                    isProcessingImage = false
                    HapticsManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    HapticsManager.shared.error()
                    isProcessingImage = false
                    errorMessage = "Unable to process receipt image"
                    showError = true
                }
            }
        }
    }
    
    private func addReceipt() {
        guard let amountDouble = Double(amount), amountDouble > 0 else {
            HapticsManager.shared.error()
            errorMessage = "Please enter a valid amount"
            showError = true
            return
        }
        
        guard !vendor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            HapticsManager.shared.error()
            errorMessage = "Please enter a vendor name"
            showError = true
            return
        }
        
        guard let userID = authService.currentUser?.id else {
            HapticsManager.shared.error()
            errorMessage = "User not logged in"
            showError = true
            return
        }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                print("🔍 Starting receipt creation...")
                print("📊 Data: amount=\(amountDouble), vendor=\(vendor), category=\(selectedCategory.rawValue)")
                
                var imageURL: String?
                
                // Upload image if selected
                if let image = selectedImage {
                    print("📤 Uploading receipt image...")
                    let receiptID = UUID().uuidString
                    do {
                        imageURL = try await viewModel.uploadReceiptImage(image, receiptID: receiptID)
                        print("✅ Image uploaded: \(imageURL ?? "nil")")
                    } catch {
                        // Show error but still allow receipt creation
                        print("⚠️ Image upload failed: \(error.localizedDescription)")
                        await MainActor.run {
                            errorMessage = "Image upload failed, but receipt will be saved without image"
                            showError = true
                        }
                        // Continue - receipt will be saved without image
                    }
                } else {
                    print("ℹ️ No image selected, proceeding without image")
                }
                
                // Use user-selected category, or AI suggestion as fallback
                let categoryToUse = selectedCategory.rawValue
                let (_, categoryConfidence) = AIService.shared.categorizeReceiptDetailed(vendor: vendor, amount: amountDouble)
                
                // Use preSelectedJob if available, otherwise use selectedJob
                let jobToUse = preSelectedJob ?? selectedJob
                
                // IMPORTANT: Use job's ownerID, not the current user's ID
                // This allows workers to submit receipts that appear on the owner's account
                let receiptOwnerID = jobToUse?.ownerID ?? userID
                
                print("📝 Creating receipt with ownerID: \(receiptOwnerID), jobID: \(jobToUse?.id ?? "nil")")
                
                let receipt = Receipt(
                    ownerID: receiptOwnerID,
                    jobID: jobToUse?.id,
                    amount: amountDouble,
                    vendor: vendor,
                    category: categoryToUse,
                    date: date,
                    imageURL: imageURL,
                    notes: notes,
                    createdAt: Date(),
                    aiProcessed: true,
                    aiConfidence: aiConfidence > 0 ? aiConfidence : categoryConfidence,
                    aiFlags: aiFlags.isEmpty ? nil : aiFlags,
                    aiSuggestedCategory: categoryToUse
                )
                
                print("🚀 Calling viewModel.createReceipt...")
                try await viewModel.createReceipt(receipt)
                print("✅ Receipt created successfully!")
                
                await MainActor.run {
                    HapticsManager.shared.success()
                    dismiss()
                }
            } catch {
                print("❌ Receipt creation failed: \(error)")
                print("❌ Error details: \(error.localizedDescription)")
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
