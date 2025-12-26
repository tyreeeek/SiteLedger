import SwiftUI

struct DocumentDetailView: View {
    let document: Document
    @Environment(\.dismiss) var dismiss
    @State private var showingFullImage = false
    
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
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    // Document Preview
                    ModernCard(shadow: true) {
                        VStack(spacing: ModernDesign.Spacing.md) {
                            if document.fileType == .image, let url = URL(string: document.fileURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 300)
                                            .cornerRadius(ModernDesign.Radius.medium)
                                            .onTapGesture {
                                                showingFullImage = true
                                            }
                                    case .failure(_):
                                        VStack(spacing: ModernDesign.Spacing.md) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(ModernDesign.Colors.warning)
                                            Text("Failed to load image")
                                                .font(ModernDesign.Typography.body)
                                                .foregroundColor(ModernDesign.Colors.textSecondary)
                                        }
                                        .frame(height: 200)
                                    case .empty:
                                        ProgressView()
                                            .frame(height: 200)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                VStack(spacing: ModernDesign.Spacing.lg) {
                                    ZStack {
                                        Circle()
                                            .fill(categoryColor.opacity(0.1))
                                            .frame(width: 100, height: 100)
                                        
                                        Image(systemName: categoryIcon)
                                            .font(.system(size: 44))
                                            .foregroundColor(categoryColor)
                                    }
                                    
                                    Text("Tap to view document")
                                        .font(ModernDesign.Typography.body)
                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                    
                                    if let url = URL(string: document.fileURL) {
                                        Link(destination: url) {
                                            HStack {
                                                Image(systemName: "arrow.up.forward.app")
                                                Text("Open in Browser")
                                            }
                                            .font(ModernDesign.Typography.label)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, ModernDesign.Spacing.xl)
                                            .padding(.vertical, ModernDesign.Spacing.md)
                                            .background(ModernDesign.Colors.primary)
                                            .cornerRadius(ModernDesign.Radius.medium)
                                        }
                                    }
                                }
                                .padding(.vertical, ModernDesign.Spacing.xl)
                            }
                        }
                    }
                    
                    // Document Info
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.lg) {
                            ModernSectionHeader(title: "Document Info")
                            
                            VStack(spacing: ModernDesign.Spacing.md) {
                                DocumentInfoRow(label: "Title", value: document.title)
                                
                                if let category = document.documentCategory {
                                    DocumentInfoRow(label: "Type", value: category.rawValue.capitalized, color: categoryColor)
                                }
                                
                                DocumentInfoRow(label: "File Type", value: document.fileType.rawValue.uppercased())
                                
                                DocumentInfoRow(label: "Created", value: document.createdAt.formatted(.dateTime.month(.abbreviated).day().year()))
                            }
                        }
                    }
                    
                    // AI Analysis
                    if document.aiProcessed {
                        ModernCard(shadow: true) {
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.lg) {
                                HStack {
                                    ModernSectionHeader(title: "AI Analysis")
                                    Spacer()
                                    if let confidence = document.aiConfidence {
                                        HStack(spacing: ModernDesign.Spacing.xs) {
                                            Image(systemName: confidence >= 0.8 ? "checkmark.seal.fill" : "exclamationmark.circle.fill")
                                                .foregroundColor(confidence >= 0.8 ? ModernDesign.Colors.success : ModernDesign.Colors.warning)
                                            Text("\(Int(confidence * 100))% confidence")
                                                .font(ModernDesign.Typography.caption)
                                                .foregroundColor(ModernDesign.Colors.textSecondary)
                                        }
                                    }
                                }
                                
                                if let summary = document.aiSummary, !summary.isEmpty {
                                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                        Text("Summary")
                                            .font(ModernDesign.Typography.labelSmall)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                        Text(summary)
                                            .font(ModernDesign.Typography.body)
                                            .foregroundColor(ModernDesign.Colors.textPrimary)
                                    }
                                }
                                
                                if let extractedData = document.aiExtractedData, !extractedData.isEmpty {
                                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
                                        Text("Extracted Data")
                                            .font(ModernDesign.Typography.labelSmall)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                        
                                        ForEach(Array(extractedData.keys.sorted()), id: \.self) { key in
                                            HStack {
                                                Text(key.capitalized)
                                                    .font(ModernDesign.Typography.caption)
                                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                                Spacer()
                                                Text(extractedData[key] ?? "")
                                                    .font(ModernDesign.Typography.label)
                                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                                            }
                                        }
                                    }
                                }
                                
                                if let flags = document.aiFlags, !flags.isEmpty {
                                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                        Text("Flags")
                                            .font(ModernDesign.Typography.labelSmall)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                        
                                        HStack {
                                            ForEach(flags, id: \.self) { flag in
                                                Text(flag.replacingOccurrences(of: "_", with: " ").capitalized)
                                                    .font(ModernDesign.Typography.captionSmall)
                                                    .foregroundColor(ModernDesign.Colors.warning)
                                                    .padding(.horizontal, ModernDesign.Spacing.sm)
                                                    .padding(.vertical, ModernDesign.Spacing.xs)
                                                    .background(ModernDesign.Colors.warning.opacity(0.1))
                                                    .cornerRadius(ModernDesign.Radius.small)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Notes
                    if !document.notes.isEmpty {
                        ModernCard(shadow: true) {
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                                ModernSectionHeader(title: "Notes")
                                
                                Text(document.notes)
                                    .font(ModernDesign.Typography.body)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                            }
                        }
                    }
                }
                .padding(ModernDesign.Spacing.lg)
                .padding(.bottom, ModernDesign.Spacing.xxxl)
            }
        }
        .navigationTitle("Document Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingFullImage) {
            FullImageView(imageURL: document.fileURL)
        }
    }
}

struct DocumentInfoRow: View {
    let label: String
    let value: String
    var color: Color = ModernDesign.Colors.textPrimary
    
    var body: some View {
        HStack {
            Text(label)
                .font(ModernDesign.Typography.body)
                .foregroundColor(ModernDesign.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(ModernDesign.Typography.label)
                .foregroundColor(color)
        }
    }
}

struct FullImageView: View {
    let imageURL: String
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(scale)
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            scale = value
                                        }
                                        .onEnded { _ in
                                            withAnimation {
                                                scale = max(1.0, min(scale, 4.0))
                                            }
                                        }
                                )
                        case .failure(_):
                            VStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                                Text("Failed to load image")
                                    .foregroundColor(.white)
                            }
                        case .empty:
                            ProgressView()
                                .tint(.white)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DocumentDetailView(document: Document(
            ownerID: "owner123",
            jobID: nil,
            fileURL: "https://example.com/doc.pdf",
            fileType: .pdf,
            title: "Sample Contract",
            notes: "This is a sample contract for testing",
            createdAt: Date(),
            aiProcessed: true,
            aiSummary: "This is a contract for home renovation services",
            aiExtractedData: ["client": "John Doe", "amount": "$50,000"],
            aiConfidence: 0.92,
            aiFlags: nil,
            documentCategory: .contract
        ))
    }
}
