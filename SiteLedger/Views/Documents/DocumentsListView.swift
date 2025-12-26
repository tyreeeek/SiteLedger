import SwiftUI
import UniformTypeIdentifiers

struct DocumentsListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = DocumentsViewModel()
    @StateObject private var jobsViewModel = JobsViewModel()
    
    @State private var showingAddDocument = false
    @State private var searchText = ""
    @State private var selectedCategory: Document.DocumentCategory?
    @State private var selectedJob: Job?
    @State private var sortOption: SortOption = .dateNewest
    
    enum SortOption: String, CaseIterable {
        case dateNewest = "Date (Newest)"
        case dateOldest = "Date (Oldest)"
        case titleAZ = "Title (A-Z)"
        case confidence = "AI Confidence"
    }
    
    var filteredDocuments: [Document] {
        var filtered = viewModel.documents
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { document in
                document.title.localizedCaseInsensitiveContains(searchText) ||
                document.notes.localizedCaseInsensitiveContains(searchText) ||
                (document.aiSummary ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.documentCategory == category }
        }
        
        // Job filter
        if let job = selectedJob {
            filtered = filtered.filter { $0.jobID == job.id }
        }
        
        // Sort
        switch sortOption {
        case .dateNewest:
            filtered.sort { $0.createdAt > $1.createdAt }
        case .dateOldest:
            filtered.sort { $0.createdAt < $1.createdAt }
        case .titleAZ:
            filtered.sort { $0.title < $1.title }
        case .confidence:
            filtered.sort { ($0.aiConfidence ?? 0) > ($1.aiConfidence ?? 0) }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        HStack {
                            Text("Documents")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            Button(action: { showingAddDocument = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(AppTheme.primaryColor)
                            }
                        }
                        
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppTheme.textSecondary)
                            TextField("Search documents...", text: $searchText)
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .padding(DesignSystem.Spacing.medium)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        
                        // Filters
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSystem.Spacing.small) {
                                // Category filter
                                Menu {
                                    Button("All Categories") {
                                        selectedCategory = nil
                                    }
                                    ForEach([Document.DocumentCategory.contract, .invoice, .estimate, .permit, .receipt, .photo, .blueprint, .other], id: \.self) { category in
                                        Button(category.rawValue.capitalized) {
                                            selectedCategory = category
                                        }
                                    }
                                } label: {
                                    FilterChip(
                                        title: selectedCategory?.rawValue.capitalized ?? "Category",
                                        isSelected: selectedCategory != nil
                                    )
                                }
                                
                                // Job filter
                                Menu {
                                    Button("All Jobs") {
                                        selectedJob = nil
                                    }
                                    ForEach(jobsViewModel.jobs) { job in
                                        Button(job.jobName) {
                                            selectedJob = job
                                        }
                                    }
                                } label: {
                                    FilterChip(
                                        title: selectedJob?.jobName ?? "Job",
                                        isSelected: selectedJob != nil
                                    )
                                }
                                
                                // Sort menu
                                Menu {
                                    ForEach(SortOption.allCases, id: \.self) { option in
                                        Button(option.rawValue) {
                                            sortOption = option
                                        }
                                    }
                                } label: {
                                    FilterChip(title: "Sort", isSelected: false)
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                    .padding()
                    .background(AppTheme.backgroundColor)
                    
                    // Document list
                    if filteredDocuments.isEmpty {
                        VStack {
                            Spacer()
                            EmptyStateView(
                                icon: viewModel.documents.isEmpty ? "doc.text" : "magnifyingglass",
                                title: viewModel.documents.isEmpty ? "No Documents Yet" : "No Matching Documents",
                                message: viewModel.documents.isEmpty ? "Upload documents to keep everything organized" : "Try adjusting your filters or search",
                                action: nil,
                                buttonTitle: nil
                            )
                            
                            if viewModel.documents.isEmpty {
                                Button {
                                    HapticsManager.shared.light()
                                    showingAddDocument = true
                                } label: {
                                    Text("Upload Document")
                                        .font(DesignSystem.TextStyle.buttonLabel)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: DesignSystem.Layout.buttonHeight)
                                        .background(DesignSystem.Colors.primary)
                                        .cornerRadius(DesignSystem.Layout.buttonRadius)
                                }
                                .padding(.horizontal, 40)
                                .padding(.top, DesignSystem.Spacing.medium)
                            }
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: DesignSystem.Spacing.medium) {
                                ForEach(filteredDocuments, id: \.id) { document in
                                    EnhancedDocumentCard(document: document)
                                        .id(document.id ?? UUID().uuidString)
                                }
                            }
                            .padding()
                            .padding(.bottom, DesignSystem.Spacing.huge)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if let userID = authService.currentUser?.id {
                    viewModel.loadDocuments(userID: userID)
                    jobsViewModel.loadJobs(userID: userID)
                }
            }
            .sheet(isPresented: $showingAddDocument) {
                AddDocumentView()
            }
        }
    }
}

// MARK: - Filter Chip Component

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.tiny) {
            Text(title)
                .font(.subheadline)
            Image(systemName: "chevron.down")
                .font(.caption)
        }
        .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? AppTheme.primaryColor : Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Enhanced Document Card with AI Display

struct EnhancedDocumentCard: View {
    let document: Document
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                HStack(spacing: DesignSystem.Spacing.medium) {
                    // Icon based on category
                    Image(systemName: iconForCategory(document.documentCategory))
                        .font(.system(size: 28))
                        .foregroundColor(colorForCategory(document.documentCategory))
                        .frame(width: 50, height: 50)
                        .background(colorForCategory(document.documentCategory).opacity(0.1))
                        .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                        Text(document.title)
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(2)
                        
                        HStack(spacing: DesignSystem.Spacing.small) {
                            Text(document.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            if let category = document.documentCategory {
                                Text(category.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(colorForCategory(category))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // AI Confidence Badge
                    if let confidence = document.aiConfidence {
                        VStack(spacing: DesignSystem.Spacing.tiny) {
                            Image(systemName: confidenceIcon(confidence))
                                .foregroundColor(confidenceColor(confidence))
                            Text("\(Int(confidence * 100))%")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(confidenceColor(confidence))
                        }
                    }
                }
                
                // AI Summary (if available)
                if let summary = document.aiSummary, !summary.isEmpty {
                    Text(summary)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
                
                // AI Flags (if any)
                if let flags = document.aiFlags, !flags.isEmpty {
                    HStack(spacing: DesignSystem.Spacing.tiny) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)
                        Text(flags.joined(separator: ", ").replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // Extracted data preview
                if let extractedData = document.aiExtractedData, !extractedData.isEmpty {
                    HStack(spacing: DesignSystem.Spacing.standard) {
                        if let amount = extractedData["amount"] {
                            DataBadge(icon: "dollarsign.circle.fill", value: amount, color: .green)
                        }
                        if let clientName = extractedData["clientName"] {
                            DataBadge(icon: "person.circle.fill", value: clientName, color: .blue)
                        }
                        if let date = extractedData["date"] {
                            DataBadge(icon: "calendar.circle.fill", value: date, color: .purple)
                        }
                    }
                }
            }
        }
    }
    
    private func iconForCategory(_ category: Document.DocumentCategory?) -> String {
        guard let category = category else { return "doc.fill" }
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
    
    private func colorForCategory(_ category: Document.DocumentCategory?) -> Color {
        guard let category = category else { return AppTheme.textSecondary }
        switch category {
        case .contract: return .blue
        case .invoice: return .green
        case .estimate: return .orange
        case .permit: return .purple
        case .receipt: return .red
        case .photo: return .pink
        case .blueprint: return .teal
        case .other: return AppTheme.textSecondary
        }
    }
    
    private func confidenceIcon(_ confidence: Double) -> String {
        if confidence >= 0.8 {
            return "checkmark.seal.fill"
        } else if confidence >= 0.5 {
            return "checkmark.circle.fill"
        } else {
            return "exclamationmark.circle.fill"
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

struct DataBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.tiny) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text(value)
                .font(.caption2)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

struct DocumentCardView: View {
    let document: Document
    
    var body: some View {
        CardView {
            HStack(spacing: DesignSystem.Spacing.standard) {
                Image(systemName: iconForFileType(document.fileType))
                    .font(.title)
                    .foregroundColor(AppTheme.primaryColor)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(document.notes.isEmpty ? "Document" : document.notes)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                    
                    Text(document.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Text(document.fileType.rawValue.uppercased())
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.primaryColor)
                        .cornerRadius(6)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
    
    private func iconForFileType(_ type: Document.DocumentType) -> String {
        switch type {
        case .pdf:
            return "doc.text.fill"
        case .image:
            return "photo.fill"
        case .other:
            return "doc.fill"
        }
    }
}

struct AddDocumentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = DocumentsViewModel()
    @StateObject private var jobsViewModel = JobsViewModel()
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingFilePicker = false
    @State private var notes = ""
    @State private var selectedJob: Job?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // MARK: - AI Processing State (Phase 8)
    @State private var isProcessingAI = false
    @State private var aiResult: AIService.DocumentProcessingResult?
    @State private var documentTitle = ""
    @State private var selectedCategory: Document.DocumentCategory?
    @State private var extractedData: [String: String] = [:]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        // MARK: - Image Preview & AI Processing
                        if let image = selectedImage {
                            VStack(spacing: 12) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(AppTheme.cornerRadius)
                                    .overlay(
                                        Button(action: { 
                                            selectedImage = nil
                                            aiResult = nil
                                            documentTitle = ""
                                            selectedCategory = nil
                                            extractedData = [:]
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color.black.opacity(0.5)))
                                        }
                                        .padding(8),
                                        alignment: .topTrailing
                                    )
                                
                                if isProcessingAI {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryColor))
                                        Text("AI is analyzing document...")
                                            .font(.subheadline)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                    .padding(.vertical, 8)
                                }
                                
                                if let result = aiResult {
                                    AIExtractionResultsView(
                                        result: result,
                                        documentTitle: $documentTitle,
                                        selectedCategory: $selectedCategory,
                                        extractedData: $extractedData
                                    )
                                }
                            }
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.badge.plus")
                                    .font(.system(size: 50))
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                Text("Upload Document")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                VStack(spacing: 8) {
                                    SecondaryButton(title: "Take Photo") {
                                        showingCamera = true
                                    }
                                    
                                    SecondaryButton(title: "Choose Photo") {
                                        showingImagePicker = true
                                    }
                                    
                                    SecondaryButton(title: "Choose PDF") {
                                        showingFilePicker = true
                                    }
                                }
                            }
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(AppTheme.cornerRadius)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Assign to Job (Optional)")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            
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
                                    Text(selectedJob?.jobName ?? "Select Job")
                                        .foregroundColor(selectedJob == nil ? AppTheme.textSecondary : AppTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(AppTheme.cornerRadius)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(AppTheme.cornerRadius)
                        }
                        
                        if showError {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(AppTheme.errorColor)
                        }
                        
                        PrimaryButton(title: "Upload Document", action: uploadDocument, isLoading: isLoading)
                            .padding(.top)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
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
            }
            .onChange(of: selectedImage) {
                if let image = selectedImage {
                    processImageWithAI(image)
                }
            }
        }
    }
    
    // MARK: - AI Processing (Phase 8)
    
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
        guard selectedImage != nil else {
            errorMessage = "Please select a document"
            showError = true
            return
        }
        
        guard let userID = authService.currentUser?.id else { return }
        
        // Use AI-extracted title or default
        let finalTitle = documentTitle.isEmpty ? "Document - \(Date().formatted())" : documentTitle
        
        isLoading = true
        showError = false
        
        Task {
            do {
                try await viewModel.createDocument(
                    ownerID: userID,
                    jobID: selectedJob?.id,
                    name: finalTitle,
                    type: "image",
                    fileURL: nil,
                    notes: notes.isEmpty ? nil : notes
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - AI Extraction Results View (Phase 8)

struct AIExtractionResultsView: View {
    let result: AIService.DocumentProcessingResult
    @Binding var documentTitle: String
    @Binding var selectedCategory: Document.DocumentCategory?
    @Binding var extractedData: [String: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Confidence Badge
            HStack {
                Text("AI Analysis")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: confidenceIcon)
                        .foregroundColor(confidenceColor)
                    Text("\(Int(result.confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(confidenceColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(confidenceColor.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Flags (if any)
            if !result.flags.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(result.flags, id: \.self) { flag in
                            Text(flag.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Document Title (Editable)
            VStack(alignment: .leading, spacing: 4) {
                Text("Document Title")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                TextField("Title", text: $documentTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Document Category (Editable)
            VStack(alignment: .leading, spacing: 4) {
                Text("Category")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                Menu {
                    ForEach([Document.DocumentCategory.contract, .invoice, .estimate, .permit, .receipt, .photo, .blueprint, .other], id: \.self) { category in
                        Button(category.rawValue.capitalized) {
                            selectedCategory = category
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedCategory?.rawValue.capitalized ?? "Select Category")
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Extracted Data
            if !extractedData.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Extracted Information")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    VStack(spacing: 8) {
                        ForEach(Array(extractedData.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text(formatFieldName(key))
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .frame(width: 100, alignment: .leading)
                                Text(extractedData[key] ?? "")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            
            // AI Summary
            if !result.summary.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Summary")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text(result.summary)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var confidenceIcon: String {
        if result.confidence >= 0.8 {
            return "checkmark.seal.fill"
        } else if result.confidence >= 0.5 {
            return "checkmark.circle.fill"
        } else {
            return "exclamationmark.circle.fill"
        }
    }
    
    private var confidenceColor: Color {
        if result.confidence >= 0.8 {
            return .green
        } else if result.confidence >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func formatFieldName(_ key: String) -> String {
        key.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
            .capitalized
    }
}

