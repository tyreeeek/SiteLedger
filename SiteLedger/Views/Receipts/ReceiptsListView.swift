import SwiftUI

struct ReceiptsListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = ReceiptsViewModel()
    @State private var showingAddReceipt = false
    @State private var filterType: FilterType = .all
    
    enum FilterType {
        case all, recent, highValue
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                        // Modern Header
                        ScreenHeader(
                            title: "Receipts",
                            subtitle: "\(viewModel.receipts.count) total",
                            action: { /* Filter/Sort action */ },
                            actionIcon: "line.3.horizontal.decrease.circle"
                        )
                        
                        // Summary Card
                        CardView {
                            HStack {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                                    Text("Total Amount")
                                        .font(DesignSystem.TextStyle.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    Text("$\(String(format: "%.2f", totalAmount))")
                                        .font(DesignSystem.TextStyle.title2)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                }
                                Spacer()
                                Image(systemName: "receipt")
                                    .font(.system(size: 32))
                                    .foregroundColor(AppTheme.primaryColor.opacity(0.3))
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                        
                        if filteredReceipts.isEmpty {
                            EmptyStateView(
                                icon: "receipt",
                                title: "No Receipts Yet",
                                message: "Add your first receipt to store documents",
                                action: { showingAddReceipt = true },
                                buttonTitle: "Add Receipt"
                            )
                        } else {
                            VStack(spacing: DesignSystem.Spacing.medium) {
                                ForEach(filteredReceipts, id: \.id) { receipt in
                                    NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                                        HStack(spacing: DesignSystem.Spacing.medium) {
                                            Image(systemName: "receipt.fill")
                                                .font(DesignSystem.TextStyle.bodyPrimary)
                                                .foregroundColor(AppTheme.primaryColor)
                                            
                                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                                                Text(receipt.vendor ?? "Unknown Vendor")
                                                    .font(DesignSystem.TextStyle.bodyBold)
                                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                                HStack(spacing: DesignSystem.Spacing.small) {
                                                    Text((receipt.date ?? Date()).formatted(date: .abbreviated, time: .omitted))
                                                        .font(DesignSystem.TextStyle.caption)
                                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                                    if let notes = receipt.notes, !notes.isEmpty {
                                                        Text("•")
                                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                                        Text(notes)
                                                            .font(DesignSystem.TextStyle.caption)
                                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                                            .lineLimit(1)
                                                    }
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.tiny) {
                                                Text("$\(String(format: "%.2f", receipt.amount ?? 0))")
                                                    .font(DesignSystem.TextStyle.bodySecondary)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(AppTheme.textPrimary)
                                                
                                                Text("Document")
                                                    .font(DesignSystem.TextStyle.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(AppTheme.primaryColor)
                                                    .padding(.horizontal, DesignSystem.Spacing.small)
                                                    .padding(.vertical, DesignSystem.Spacing.tiny)
                                                    .background(AppTheme.primaryColor.opacity(0.1))
                                                    .cornerRadius(6)
                                            }
                                        }
                                        .padding(DesignSystem.Spacing.cardPadding)
                                        .background(AppTheme.cardBackground)
                                        .cornerRadius(AppTheme.cornerRadius)
                                        .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                        }
                    }
                    .padding(.top, DesignSystem.Spacing.cardPadding)
                    .padding(.bottom, DesignSystem.Spacing.huge)
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
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(AppTheme.primaryColor)
                                .clipShape(Circle())
                                .shadow(color: AppTheme.primaryColor.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, DesignSystem.Spacing.large)
                        .padding(.bottom, DesignSystem.Spacing.extraLarge)
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                if let userID = authService.currentUser?.id {
                    viewModel.loadReceipts(userID: userID)
                }
            }
            .refreshable {
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
                AddReceiptView()
            }
        }
    }
    
    private var filteredReceipts: [Receipt] {
        return viewModel.receipts
    }
    
    private var totalAmount: Double {
        return viewModel.receipts.reduce(0) { $0 + ($1.amount ?? 0) }
    }
    
}

// MARK: - Receipt Card View (Modernized inline)
