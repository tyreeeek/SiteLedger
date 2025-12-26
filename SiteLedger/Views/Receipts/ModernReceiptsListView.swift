import SwiftUI

struct ModernReceiptsListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = ReceiptsViewModel()
    @State private var showingAddReceipt = false
    @State private var searchText = ""
    @State private var selectedFilter: ReceiptFilterType = .all
    
    enum ReceiptFilterType: String, CaseIterable {
        case all = "All"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
    }
    
    var filteredReceipts: [Receipt] {
        var receipts = viewModel.receipts
        
        // Apply date filter
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedFilter {
        case .all:
            break
        case .thisWeek:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            receipts = receipts.filter { ($0.date ?? Date.distantPast) >= weekAgo }
        case .thisMonth:
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            receipts = receipts.filter { ($0.date ?? Date.distantPast) >= monthStart }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            receipts = receipts.filter { receipt in
                (receipt.vendor ?? "").localizedCaseInsensitiveContains(searchText) ||
                (receipt.notes ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return receipts
    }
    
    var totalAmount: Double {
        filteredReceipts.reduce(0) { $0 + ($1.amount ?? 0) }
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
                                Text("Receipts")
                                    .font(ModernDesign.Typography.displayMedium)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                                
                                Text("\(filteredReceipts.count) receipts")
                                    .font(ModernDesign.Typography.bodySmall)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                HapticsManager.shared.light()
                                showingAddReceipt = true
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
                            
                            TextField("Search receipts...", text: $searchText)
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
                                ForEach(ReceiptFilterType.allCases, id: \.self) { filter in
                                    ReceiptFilterChip(
                                        title: filter.rawValue,
                                        isSelected: selectedFilter == filter,
                                        action: {
                                            HapticsManager.shared.selection()
                                            selectedFilter = filter
                                        }
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
                    } else if filteredReceipts.isEmpty {
                        Spacer()
                        EmptyReceiptsState(
                            hasReceipts: !viewModel.receipts.isEmpty,
                            searchText: searchText,
                            action: { showingAddReceipt = true }
                        )
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                // Summary Card
                                ReceiptsSummaryCard(
                                    totalAmount: totalAmount,
                                    receiptCount: filteredReceipts.count
                                )
                                
                                // Receipts List
                                LazyVStack(spacing: ModernDesign.Spacing.md) {
                                    ForEach(filteredReceipts.filter { $0.id != nil }) { receipt in
                                        NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                                            ModernReceiptCard(receipt: receipt)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                deleteReceipt(receipt)
                                            } label: {
                                                Label("Delete", systemImage: "trash.fill")
                                            }
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
                                viewModel.loadReceipts(userID: userID)
                            }
                        }
                    }
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            HapticsManager.shared.medium()
                            showingAddReceipt = true
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
                    viewModel.loadReceipts(userID: userID)
                }
            }
            .sheet(isPresented: $showingAddReceipt, onDismiss: {
                // Reload receipts when the add sheet is dismissed
                if let userID = authService.currentUser?.id {
                    viewModel.loadReceipts(userID: userID)
                }
            }) {
                ModernAddReceiptView()
            }
        }
    }
    
    private func deleteReceipt(_ receipt: Receipt) {
        HapticsManager.shared.error()
        
        Task {
            do {
                try await viewModel.deleteReceipt(receipt)
                HapticsManager.shared.success()
                if let userID = authService.currentUser?.id {
                    viewModel.loadReceipts(userID: userID)
                }
            } catch {
                print("Error deleting receipt: \(error)")
            }
        }
    }
}

struct ReceiptsSummaryCard: View {
    let totalAmount: Double
    let receiptCount: Int
    
    var body: some View {
        ModernCard(shadow: true) {
            HStack(spacing: ModernDesign.Spacing.lg) {
                // Total Amount (document only - no financial impact)
                VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                    Text("Total Amount")
                        .font(ModernDesign.Typography.labelSmall)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                        .adaptiveText(allowsMultipleLines: false, minimumScaleFactor: 0.85)
                    
                    Text("$\(String(format: "%.2f", totalAmount))")
                        .font(ModernDesign.Typography.title1)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                        .adaptiveText(allowsMultipleLines: false, minimumScaleFactor: 0.85)
                }
                
                Spacer()
                
                // Receipt Count
                VStack(alignment: .trailing, spacing: ModernDesign.Spacing.xs) {
                    Text("Receipts")
                        .font(ModernDesign.Typography.labelSmall)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                    
                    Text("\(receiptCount)")
                        .font(ModernDesign.Typography.title2)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                }
            }
        }
    }
}

struct ModernReceiptCard: View {
    let receipt: Receipt
    
    private var categoryIcon: String {
        switch receipt.category?.lowercased() ?? "materials" {
        case "materials":
            return "shippingbox.fill"
        case "tools":
            return "hammer.fill"
        case "electrical":
            return "bolt.fill"
        case "labor":
            return "person.fill"
        case "equipment":
            return "wrench.and.screwdriver.fill"
        case "permit":
            return "doc.fill"
        case "other":
            return "questionmark.circle.fill"
        default:
            return "doc.text.fill"
        }
    }
    
    private var categoryColor: Color {
        switch receipt.category?.lowercased() ?? "materials" {
        case "materials":
            return .orange
        case "tools":
            return .red
        case "electrical":
            return .yellow
        case "labor":
            return .blue
        case "equipment":
            return .green
        case "permit":
            return .purple
        default:
            return .gray
        }
    }
    
    var body: some View {
        ModernCard(shadow: true) {
            HStack(spacing: ModernDesign.Spacing.md) {
                // Receipt Icon/Photo
                ZStack {
                    RoundedRectangle(cornerRadius: ModernDesign.Radius.small)
                        .fill(categoryColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    if let imageURL = receipt.imageURL, !imageURL.isEmpty {
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: ModernDesign.Radius.small))
                            default:
                                Image(systemName: categoryIcon)
                                    .font(.system(size: 22))
                                    .foregroundColor(categoryColor)
                            }
                        }
                    } else {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 22))
                            .foregroundColor(categoryColor)
                    }
                }
                
                // Receipt Info
                VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                    Text(receipt.vendor ?? "Unknown Vendor")
                        .font(ModernDesign.Typography.labelLarge)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                        .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                    
                    HStack(spacing: ModernDesign.Spacing.xs) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                        
                        Text((receipt.date ?? Date()).formatted(.dateTime.month(.abbreviated).day()))
                            .font(ModernDesign.Typography.caption)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                            .adaptiveText(allowsMultipleLines: false, minimumScaleFactor: 0.85)
                        
                        if !(receipt.notes ?? "").isEmpty {
                            Text("•")
                                .foregroundColor(ModernDesign.Colors.textTertiary)
                            Text(receipt.notes ?? "")
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.textTertiary)
                                .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Amount and Chevron
                VStack(alignment: .trailing, spacing: ModernDesign.Spacing.xs) {
                    Text("$\(String(format: "%.2f", receipt.amount ?? 0))")
                        .font(ModernDesign.Typography.title3)
                        .foregroundColor(categoryColor)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                }
            }
        }
    }
}

struct ReceiptFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ModernDesign.Typography.labelSmall)
                .foregroundColor(isSelected ? .white : ModernDesign.Colors.textSecondary)
                .padding(.horizontal, ModernDesign.Spacing.md)
                .padding(.vertical, ModernDesign.Spacing.sm)
                .background(isSelected ? ModernDesign.Colors.primary : ModernDesign.Colors.cardBackground)
                .cornerRadius(ModernDesign.Radius.round)
                .shadow(color: isSelected ? ModernDesign.Shadow.small.color : .clear,
                       radius: ModernDesign.Shadow.small.radius,
                       x: ModernDesign.Shadow.small.x,
                       y: ModernDesign.Shadow.small.y)
        }
    }
}

struct EmptyReceiptsState: View {
    let hasReceipts: Bool
    let searchText: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: ModernDesign.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(ModernDesign.Colors.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: hasReceipts ? "magnifyingglass" : "receipt")
                    .font(.system(size: 40))
                    .foregroundColor(ModernDesign.Colors.primary)
            }
            
            VStack(spacing: ModernDesign.Spacing.sm) {
                Text(hasReceipts ? "No Results" : "No Receipts Yet")
                    .font(ModernDesign.Typography.title2)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
                
                Text(hasReceipts ? "Try adjusting your search or filters" : "Add your first receipt to store documents")
                    .font(ModernDesign.Typography.body)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if !hasReceipts {
                ModernButton(
                    title: "Add Receipt",
                    icon: "plus.circle.fill",
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
