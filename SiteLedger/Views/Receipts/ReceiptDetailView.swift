import SwiftUI

struct ReceiptDetailView: View {
    let receipt: Receipt
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ReceiptsViewModel()
    @State private var showingDeleteAlert = false
    @State private var showingFullImage = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.medium) {
                    if let imageURLString = receipt.imageURL,
                       let imageURL = URL(string: imageURLString) {
                        Button(action: { showingFullImage = true }) {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 300)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 300)
                                        .cornerRadius(AppTheme.cornerRadius)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                                .stroke(AppTheme.primaryColor.opacity(0.3), lineWidth: 2)
                                        )
                                        .overlay(
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    Spacer()
                                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.white)
                                                        .padding(8)
                                                        .background(Color.black.opacity(0.6))
                                                        .clipShape(Circle())
                                                        .padding(8)
                                                }
                                            }
                                        )
                                case .failure:
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo.badge.exclamationmark")
                                            .font(.system(size: 60))
                                            .foregroundColor(AppTheme.textSecondary)
                                        Text("Failed to load image")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                    .frame(height: 300)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(AppTheme.textSecondary)
                            Text("No image attached")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.textSecondary.opacity(0.05))
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                    
                    CardView {
                        VStack(spacing: 16) {
                            HStack {
                                // Receipts are documents only - neutral icon
                                Image(systemName: "doc.text.fill")
                                    .font(.title)
                                    .foregroundColor(AppTheme.primaryColor)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Document")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text("$\(String(format: "%.2f", receipt.amount ?? 0))")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                
                                Spacer()
                            }
                            
                            Divider()
                            
                            DetailRow(label: "Vendor", value: receipt.vendor ?? "Unknown")
                            DetailRow(label: "Date", value: (receipt.date ?? Date()).formatted(date: .long, time: .omitted))
                            
                            if !(receipt.notes ?? "").isEmpty {
                                Divider()
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Notes")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text(receipt.notes ?? "")
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                            }
                        }
                    }
                    
                    Button(action: { showingDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Receipt")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.errorColor)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Receipt Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Receipt", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteReceipt()
            }
        } message: {
            Text("Are you sure you want to delete this receipt? This action cannot be undone.")
        }
        .fullScreenCover(isPresented: $showingFullImage) {
            if let imageURLString = receipt.imageURL,
               let imageURL = URL(string: imageURLString) {
                FullScreenImageView(imageURL: imageURL)
            }
        }
    }
    
    private func deleteReceipt() {
        guard receipt.id != nil else { return }
        
        Task {
            do {
                try await viewModel.deleteReceipt(receipt)
                await MainActor.run {
                    dismiss()
                }
            } catch {
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundColor(AppTheme.textPrimary)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Full Screen Image Viewer
struct FullScreenImageView: View {
    let imageURL: URL
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    if scale < 1.0 {
                                        withAnimation {
                                            scale = 1.0
                                            lastScale = 1.0
                                        }
                                    } else if scale > 5.0 {
                                        withAnimation {
                                            scale = 5.0
                                            lastScale = 5.0
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                if scale > 1.0 {
                                    scale = 1.0
                                    lastScale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.0
                                    lastScale = 2.0
                                }
                            }
                        }
                case .failure:
                    VStack(spacing: 16) {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        Text("Failed to load image")
                            .foregroundColor(.white)
                    }
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}
