import SwiftUI
import UniformTypeIdentifiers

struct ModernDocumentsListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = DocumentsViewModel()
    @StateObject private var jobsViewModel = JobsViewModel()
    
    @State private var showingAddDocument = false
    @State private var searchText = ""
    @State private var selectedCategory: Document.DocumentCategory?
    @State private var selectedJob: Job?
    
    var filteredDocuments: [Document] {
        var filtered = viewModel.documents
        
        if !searchText.isEmpty {
            filtered = filtered.filter { document in
                document.title.localizedCaseInsensitiveContains(searchText) ||
                document.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.documentCategory == category }
        }
        
        if let job = selectedJob {
            filtered = filtered.filter { $0.jobID == job.id }
        }
        
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        HStack {
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                Text("Documents")
                                    .font(ModernDesign.Typography.displayMedium)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                                    .adaptiveText(allowsMultipleLines: false, minimumScaleFactor: 0.85)
                                
                                Text("\(filteredDocuments.count) documents")
                                    .font(ModernDesign.Typography.bodySmall)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                    .adaptiveText(allowsMultipleLines: false, minimumScaleFactor: 0.85)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                HapticsManager.shared.light()
                                showingAddDocument = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(ModernDesign.Colors.primary)
                            }
                        }
                        
                        // Search Bar
                        HStack(spacing: ModernDesign.Spacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                            
                            TextField("Search documents...", text: $searchText)
                                .font(ModernDesign.Typography.body)
                        }
                        .padding(ModernDesign.Spacing.md)
                        .background(ModernDesign.Colors.cardBackground)
                        .cornerRadius(ModernDesign.Radius.medium)
                        .shadow(color: ModernDesign.Shadow.small.color,
                               radius: ModernDesign.Shadow.small.radius,
                               x: ModernDesign.Shadow.small.x,
                               y: ModernDesign.Shadow.small.y)
                        
                        // Filter Chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: ModernDesign.Spacing.sm) {
                                // Category filter
                                Menu {
                                    Button("All Categories") {
                                        HapticsManager.shared.selection()
                                        selectedCategory = nil
                                    }
                                    ForEach([Document.DocumentCategory.contract, .invoice, .estimate, .permit, .receipt, .photo, .blueprint, .other], id: \.self) { category in
                                        Button(category.rawValue.capitalized) {
                                            HapticsManager.shared.selection()
                                            selectedCategory = category
                                        }
                                    }
                                } label: {
                                    DocumentFilterChip(
                                        title: selectedCategory?.rawValue.capitalized ?? "Category",
                                        isSelected: selectedCategory != nil
                                    )
                                }
                                
                                // Job filter
                                Menu {
                                    Button("All Jobs") {
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
                                    DocumentFilterChip(
                                        title: selectedJob?.jobName ?? "Job",
                                        isSelected: selectedJob != nil
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, ModernDesign.Spacing.lg)
                    .padding(.top, ModernDesign.Spacing.lg)
                    .padding(.bottom, ModernDesign.Spacing.md)
                    
                    // Content
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if filteredDocuments.isEmpty {
                        Spacer()
                        EmptyDocumentsState(
                            hasDocuments: !viewModel.documents.isEmpty,
                            action: { showingAddDocument = true }
                        )
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: ModernDesign.Spacing.md) {
                                ForEach(filteredDocuments, id: \.id) { document in
                                    NavigationLink(destination: DocumentDetailView(document: document)) {
                                        ModernDocumentCard(document: document)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .id(document.id ?? UUID().uuidString)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteDocument(document)
                                        } label: {
                                            Label("Delete", systemImage: "trash.fill")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, ModernDesign.Spacing.lg)
                            .padding(.top, ModernDesign.Spacing.sm)
                            .padding(.bottom, 100)
                        }
                        .refreshable {
                            if let userID = authService.currentUser?.id {
                                viewModel.loadDocuments(userID: userID)
                            }
                        }
                    }
                }
                
                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            HapticsManager.shared.medium()
                            showingAddDocument = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(ModernDesign.Colors.primary)
                                .clipShape(Circle())
                                .shadow(color: ModernDesign.Colors.primary.opacity(0.4),
                                       radius: 12, x: 0, y: 6)
                        }
                        .padding(.trailing, ModernDesign.Spacing.lg)
                        .padding(.bottom, ModernDesign.Spacing.xxl)
                    }
                }
            }
            .task {
                if let userID = authService.currentUser?.id {
                    viewModel.loadDocuments(userID: userID)
                    jobsViewModel.loadJobs(userID: userID)
                }
            }
            .sheet(isPresented: $showingAddDocument, onDismiss: {
                // Reload documents when add sheet is dismissed
                if let userID = authService.currentUser?.id {
                    viewModel.loadDocuments(userID: userID)
                }
            }) {
                ModernAddDocumentView()
            }
        }
    }
    
    private func deleteDocument(_ document: Document) {
        HapticsManager.shared.error()
        
        Task {
            do {
                try await viewModel.deleteDocument(document)
                HapticsManager.shared.success()
                if let userID = authService.currentUser?.id {
                    viewModel.loadDocuments(userID: userID)
                }
            } catch {
                print("Error deleting document: \(error)")
            }
        }
    }
}

struct ModernDocumentCard: View {
    let document: Document
    
    var categoryColor: Color {
        guard let category = document.documentCategory else { return ModernDesign.Colors.textTertiary }
        switch category {
        case .contract: return ModernDesign.Colors.info
        case .invoice: return ModernDesign.Colors.success
        case .estimate: return ModernDesign.Colors.accent
        case .permit: return Color.purple
        case .receipt: return ModernDesign.Colors.error
        case .photo: return Color.pink
        case .blueprint: return Color.teal
        case .other: return ModernDesign.Colors.textTertiary
        }
    }
    
    var categoryIcon: String {
        guard let category = document.documentCategory else { return "doc.fill" }
        switch category {
        case .contract: return "doc.text.fill"
        case .invoice: return "dollarsign.circle.fill"
        case .estimate: return "chart.bar.doc.horizontal.fill"
        case .permit: return "checkmark.seal.fill"
        case .receipt: return "receipt.fill"
        case .photo: return "photo.fill"
        case .blueprint: return "map.fill"
        case .other: return "doc.fill"
        }
    }
    
    var body: some View {
        ModernCard(shadow: true) {
            VStack(spacing: ModernDesign.Spacing.md) {
                HStack(spacing: ModernDesign.Spacing.md) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: ModernDesign.Radius.small)
                            .fill(categoryColor.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: categoryIcon)
                            .font(.system(size: 22))
                            .foregroundColor(categoryColor)
                    }
                    
                    // Info
                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                        Text(document.title)
                            .font(ModernDesign.Typography.labelLarge)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                            .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                            .lineLimit(2)
                        
                        HStack(spacing: ModernDesign.Spacing.sm) {
                            Text(document.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                            
                            if let category = document.documentCategory {
                                ModernBadge(text: category.rawValue.capitalized, color: categoryColor, size: .small)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // AI Confidence
                    if let confidence = document.aiConfidence {
                        VStack(spacing: ModernDesign.Spacing.xs) {
                            Image(systemName: confidence >= 0.8 ? "checkmark.seal.fill" : "exclamationmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(confidence >= 0.8 ? ModernDesign.Colors.success : ModernDesign.Colors.warning)
                            
                            Text("\(Int(confidence * 100))%")
                                .font(ModernDesign.Typography.captionSmall)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                        }
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                }
                
                // AI Summary
                if let summary = document.aiSummary, !summary.isEmpty {
                    Text(summary)
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Extracted Data
                if let extractedData = document.aiExtractedData, !extractedData.isEmpty {
                    HStack(spacing: ModernDesign.Spacing.sm) {
                        if let amount = extractedData["amount"] {
                            DocumentDataBadge(icon: "dollarsign.circle.fill", value: amount, color: ModernDesign.Colors.success)
                        }
                        if let clientName = extractedData["clientName"] {
                            DocumentDataBadge(icon: "person.circle.fill", value: clientName, color: ModernDesign.Colors.info)
                        }
                    }
                }
            }
        }
    }
}

struct DocumentDataBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: ModernDesign.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(value)
                .font(ModernDesign.Typography.captionSmall)
                .foregroundColor(ModernDesign.Colors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, ModernDesign.Spacing.sm)
        .padding(.vertical, ModernDesign.Spacing.xs)
        .background(color.opacity(0.1))
        .cornerRadius(ModernDesign.Radius.small)
    }
}

struct DocumentFilterChip: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: ModernDesign.Spacing.xs) {
            Text(title)
                .font(ModernDesign.Typography.labelSmall)
            Image(systemName: "chevron.down")
                .font(.system(size: 10))
        }
        .foregroundColor(isSelected ? .white : ModernDesign.Colors.textSecondary)
        .padding(.horizontal, ModernDesign.Spacing.md)
        .padding(.vertical, ModernDesign.Spacing.sm)
        .background(isSelected ? ModernDesign.Colors.primary : ModernDesign.Colors.cardBackground)
        .cornerRadius(ModernDesign.Radius.round)
        .shadow(color: ModernDesign.Shadow.small.color,
               radius: ModernDesign.Shadow.small.radius,
               x: ModernDesign.Shadow.small.x,
               y: ModernDesign.Shadow.small.y)
    }
}

struct EmptyDocumentsState: View {
    let hasDocuments: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: ModernDesign.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(ModernDesign.Colors.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: hasDocuments ? "magnifyingglass" : "doc.text")
                    .font(.system(size: 40))
                    .foregroundColor(ModernDesign.Colors.primary)
            }
            
            VStack(spacing: ModernDesign.Spacing.sm) {
                Text(hasDocuments ? "No Results" : "No Documents Yet")
                    .font(ModernDesign.Typography.title2)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
                
                Text(hasDocuments ? "Try adjusting your filters" : "Upload documents to keep everything organized")
                    .font(ModernDesign.Typography.body)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if !hasDocuments {
                ModernButton(
                    title: "Upload Document",
                    icon: "doc.badge.plus",
                    style: .primary,
                    size: .large,
                    action: {
                        HapticsManager.shared.light()
                        action()
                    }
                )
            }
        }
        .padding(ModernDesign.Spacing.xl)
    }
}

struct ModernAddDocumentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = DocumentsViewModel()
    @StateObject private var jobsViewModel = JobsViewModel()
    
    // Optional: Pre-selected job when adding from Job Detail
    var preselectedJobID: String?
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingFilePicker = false
    @State private var notes = ""
    @State private var selectedJob: Job?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @State private var isProcessingAI = false
    @State private var aiResult: AIService.DocumentProcessingResult?
    @State private var documentTitle = ""
    @State private var selectedCategory: Document.DocumentCategory?
    @State private var extractedData: [String: String] = [:]
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        // Header
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                            Text("Upload Document")
                                .font(ModernDesign.Typography.displayMedium)
                                .foregroundColor(ModernDesign.Colors.textPrimary)
                            
                            Text("Add contracts, permits, photos, or other files")
                                .font(ModernDesign.Typography.body)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Upload Section
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                if let image = selectedImage {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 200)
                                            .cornerRadius(ModernDesign.Radius.medium)
                                        
                                        Button(action: {
                                            HapticsManager.shared.light()
                                            selectedImage = nil
                                            aiResult = nil
                                            documentTitle = ""
                                            selectedCategory = nil
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white)
                                                .shadow(radius: 2)
                                        }
                                        .padding(ModernDesign.Spacing.sm)
                                    }
                                    
                                    if isProcessingAI {
                                        HStack(spacing: ModernDesign.Spacing.sm) {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                            Text("AI is analyzing...")
                                                .font(ModernDesign.Typography.labelSmall)
                                                .foregroundColor(ModernDesign.Colors.textSecondary)
                                            Spacer()
                                        }
                                        .padding(ModernDesign.Spacing.md)
                                        .background(ModernDesign.Colors.info.opacity(0.1))
                                        .cornerRadius(ModernDesign.Radius.small)
                                    }
                                } else {
                                    VStack(spacing: ModernDesign.Spacing.lg) {
                                        ZStack {
                                            Circle()
                                                .fill(ModernDesign.Colors.primary.opacity(0.1))
                                                .frame(width: 80, height: 80)
                                            
                                            Image(systemName: "doc.badge.plus")
                                                .font(.system(size: 32))
                                                .foregroundColor(ModernDesign.Colors.primary)
                                        }
                                        
                                        Text("Select a document to upload")
                                            .font(ModernDesign.Typography.body)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                        
                                        HStack(spacing: ModernDesign.Spacing.md) {
                                            UploadOptionButton(icon: "camera", title: "Camera") {
                                                showingCamera = true
                                            }
                                            
                                            UploadOptionButton(icon: "photo", title: "Gallery") {
                                                showingImagePicker = true
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, ModernDesign.Spacing.xl)
                                }
                            }
                        }
                        
                        // AI Results
                        if let result = aiResult {
                            ModernCard(shadow: true) {
                                VStack(spacing: ModernDesign.Spacing.lg) {
                                    HStack {
                                        ModernSectionHeader(title: "AI Analysis")
                                        Spacer()
                                        ModernBadge(
                                            text: "\(Int(result.confidence * 100))%",
                                            color: result.confidence >= 0.8 ? ModernDesign.Colors.success : ModernDesign.Colors.warning,
                                            size: .small
                                        )
                                    }
                                    
                                    ModernTextField(
                                        placeholder: "Document Title",
                                        text: $documentTitle,
                                        icon: "doc.text"
                                    )
                                    
                                    if !result.summary.isEmpty {
                                        Text(result.summary)
                                            .font(ModernDesign.Typography.bodySmall)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                            .padding(ModernDesign.Spacing.md)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(ModernDesign.Colors.background)
                                            .cornerRadius(ModernDesign.Radius.small)
                                    }
                                }
                            }
                        }
                        
                        // Document Category
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Document Type",
                                    subtitle: "Required"
                                )
                                
                                Menu {
                                    ForEach([Document.DocumentCategory.contract, .permit, .invoice, .estimate, .photo, .blueprint, .other], id: \.self) { category in
                                        Button(category.rawValue.capitalized) {
                                            HapticsManager.shared.selection()
                                            selectedCategory = category
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(ModernDesign.Colors.textTertiary)
                                        
                                        Text(selectedCategory?.rawValue.capitalized ?? "Select Type")
                                            .font(ModernDesign.Typography.body)
                                            .foregroundColor(selectedCategory == nil ? ModernDesign.Colors.textTertiary : ModernDesign.Colors.textPrimary)
                                        
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
                        
                        // Job Assignment
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
                        
                        // Error
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
                        
                        // Upload Button
                        ModernButton(
                            title: "Upload Document",
                            icon: "arrow.up.circle.fill",
                            style: .primary,
                            size: .large,
                            action: uploadDocument,
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
            .onAppear {
                if let userID = authService.currentUser?.id {
                    jobsViewModel.loadJobs(userID: userID)
                }
                // Auto-select job if preselected
                if let preselectedJobID = preselectedJobID {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        selectedJob = jobsViewModel.jobs.first { $0.id == preselectedJobID }
                    }
                }
            }
            .onChange(of: selectedImage) {
                if let image = selectedImage {
                    processImageWithAI(image)
                }
            }
        }
    }
    
    private func processImageWithAI(_ image: UIImage) {
        isProcessingAI = true
        
        Task {
            // Placeholder - AI processing not yet implemented
            await MainActor.run {
                self.isProcessingAI = false
            }
        }
    }
    
    private func uploadDocument() {
        guard let image = selectedImage else {
            HapticsManager.shared.error()
            errorMessage = "Please select a document"
            showError = true
            return
        }
        
        guard let category = selectedCategory else {
            HapticsManager.shared.error()
            errorMessage = "Please select a document type"
            showError = true
            return
        }
        
        guard let userID = authService.currentUser?.id else { return }
        
        let finalTitle = documentTitle.isEmpty ? "Document - \(Date().formatted())" : documentTitle
        
        isLoading = true
        showError = false
        
        Task {
            do {
                // Upload image first
                let documentID = UUID().uuidString
                let fileURL = try await viewModel.uploadDocument(image, documentID: documentID)
                
                // Then create document record
                try await viewModel.createDocument(
                    ownerID: userID,
                    jobID: selectedJob?.id,
                    name: finalTitle,
                    type: "image",
                    fileURL: fileURL,
                    documentCategory: category,
                    notes: notes.isEmpty ? nil : notes
                )
                
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

struct UploadOptionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.light()
            action()
        }) {
            VStack(spacing: ModernDesign.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(ModernDesign.Typography.labelSmall)
            }
            .foregroundColor(ModernDesign.Colors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ModernDesign.Spacing.lg)
            .background(ModernDesign.Colors.primary.opacity(0.1))
            .cornerRadius(ModernDesign.Radius.medium)
        }
    }
}
