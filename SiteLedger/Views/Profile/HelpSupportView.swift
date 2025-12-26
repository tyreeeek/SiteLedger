import SwiftUI

struct HelpSupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var showingContactForm = false
    
    let faqItems = [
        ModernFAQItem(
            question: "How do I create a new job?",
            answer: "Go to the Jobs tab and tap the + button in the top right corner. Fill in the job details including name, client, project value, and dates."
        ),
        ModernFAQItem(
            question: "How do I add receipts?",
            answer: "Navigate to the Receipts tab and tap 'Add Receipt'. You can take a photo of your receipt and our AI will automatically extract the details. Receipts are stored as documents and do not affect job financials."
        ),
        ModernFAQItem(
            question: "How is profit calculated?",
            answer: "Profit = Project Value - Labor Cost. Labor cost is automatically calculated from worker timesheets and hourly rates. Receipts are for document storage only."
        ),
        ModernFAQItem(
            question: "Can I assign workers to jobs?",
            answer: "Yes! Open any job and tap the people icon in the top right. You can then add or remove workers from that job."
        ),
        ModernFAQItem(
            question: "How do timesheets work?",
            answer: "Workers can clock in and out using the Timesheets feature. GPS location is recorded at clock-in to verify on-site presence."
        ),
        ModernFAQItem(
            question: "How do I export my data?",
            answer: "Go to More > Privacy & Security > Export My Data. You can download all your jobs, receipts, and timesheets."
        )
    ]
    
    var filteredFAQ: [ModernFAQItem] {
        if searchText.isEmpty {
            return faqItems
        }
        return faqItems.filter { item in
            item.question.localizedCaseInsensitiveContains(searchText) ||
            item.answer.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        // Search Bar
                        HStack(spacing: ModernDesign.Spacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                            
                            TextField("Search help topics...", text: $searchText)
                                .font(ModernDesign.Typography.body)
                        }
                        .padding(ModernDesign.Spacing.md)
                        .background(ModernDesign.Colors.cardBackground)
                        .cornerRadius(ModernDesign.Radius.medium)
                        .shadow(color: ModernDesign.Shadow.small.color,
                               radius: ModernDesign.Shadow.small.radius,
                               x: ModernDesign.Shadow.small.x,
                               y: ModernDesign.Shadow.small.y)
                        
                        // Quick Actions
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Contact Us",
                                    subtitle: "Get in touch with our support team"
                                )
                                
                                HStack(spacing: ModernDesign.Spacing.md) {
                                    ContactButton(
                                        icon: "envelope.fill",
                                        title: "Email",
                                        color: ModernDesign.Colors.primary,
                                        action: {
                                            if let url = URL(string: "mailto:support@siteledger.ai") {
                                                UIApplication.shared.open(url)
                                            }
                                        }
                                    )
                                    
                                    ContactButton(
                                        icon: "message.fill",
                                        title: "Chat",
                                        color: ModernDesign.Colors.success,
                                        action: {
                                            showingContactForm = true
                                        }
                                    )
                                    
                                    ContactButton(
                                        icon: "phone.fill",
                                        title: "Call",
                                        color: ModernDesign.Colors.accent,
                                        action: {
                                            if let url = URL(string: "tel:+18001234567") {
                                                UIApplication.shared.open(url)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        
                        // FAQ Section
                        ModernCard(shadow: true) {
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Frequently Asked Questions",
                                    subtitle: "\(filteredFAQ.count) topics"
                                )
                                
                                if filteredFAQ.isEmpty {
                                    VStack(spacing: ModernDesign.Spacing.md) {
                                        Image(systemName: "questionmark.circle")
                                            .font(.system(size: 40))
                                            .foregroundColor(ModernDesign.Colors.textTertiary)
                                        Text("No matching topics found")
                                            .font(ModernDesign.Typography.body)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, ModernDesign.Spacing.xl)
                                } else {
                                    ForEach(filteredFAQ) { item in
                                        ModernFAQItemView(item: item)
                                    }
                                }
                            }
                        }
                        
                        // Resources
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Resources",
                                    subtitle: "Learn more about SiteLedger"
                                )
                                
                                ResourceButton(
                                    icon: "book.fill",
                                    title: "User Guide",
                                    subtitle: "Complete documentation",
                                    color: ModernDesign.Colors.primary
                                )
                                
                                ResourceButton(
                                    icon: "play.rectangle.fill",
                                    title: "Video Tutorials",
                                    subtitle: "Step-by-step guides",
                                    color: ModernDesign.Colors.error
                                )
                                
                                ResourceButton(
                                    icon: "newspaper.fill",
                                    title: "What's New",
                                    subtitle: "Latest updates and features",
                                    color: ModernDesign.Colors.success
                                )
                            }
                        }
                    }
                    .padding(ModernDesign.Spacing.lg)
                    .padding(.bottom, ModernDesign.Spacing.xxxl)
                }
            }
            .navigationTitle("Help & Support")
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
            .sheet(isPresented: $showingContactForm) {
                ContactFormView()
            }
        }
    }
}

struct ModernFAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct ModernFAQItemView: View {
    let item: ModernFAQItem
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    HapticsManager.shared.light()
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(item.question)
                        .font(ModernDesign.Typography.label)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ModernDesign.Colors.primary)
                }
            }
            
            if isExpanded {
                Text(item.answer)
                    .font(ModernDesign.Typography.body)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
                    .padding(ModernDesign.Spacing.md)
                    .background(ModernDesign.Colors.background)
                    .cornerRadius(ModernDesign.Radius.small)
            }
            
            Rectangle()
                .fill(ModernDesign.Colors.border)
                .frame(height: 1)
        }
    }
}

struct ContactButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.light()
            action()
        }) {
            VStack(spacing: ModernDesign.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(ModernDesign.Typography.labelSmall)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct ResourceButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.light()
        }) {
            HStack(spacing: ModernDesign.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: ModernDesign.Radius.small)
                        .fill(color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ModernDesign.Typography.label)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ModernDesign.Colors.textTertiary)
            }
        }
    }
}

struct ContactFormView: View {
    @Environment(\.dismiss) var dismiss
    @State private var subject = ""
    @State private var message = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Send us a message",
                                    subtitle: "We'll respond within 24 hours"
                                )
                                
                                VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                    Text("Subject")
                                        .font(ModernDesign.Typography.labelSmall)
                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                    
                                    TextField("What's this about?", text: $subject)
                                        .font(ModernDesign.Typography.body)
                                        .padding(ModernDesign.Spacing.md)
                                        .background(ModernDesign.Colors.background)
                                        .cornerRadius(ModernDesign.Radius.medium)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: ModernDesign.Radius.medium)
                                                .stroke(ModernDesign.Colors.border, lineWidth: 1)
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                    Text("Message")
                                        .font(ModernDesign.Typography.labelSmall)
                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                    
                                    TextEditor(text: $message)
                                        .frame(height: 150)
                                        .font(ModernDesign.Typography.body)
                                        .padding(ModernDesign.Spacing.sm)
                                        .background(ModernDesign.Colors.background)
                                        .cornerRadius(ModernDesign.Radius.medium)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: ModernDesign.Radius.medium)
                                                .stroke(ModernDesign.Colors.border, lineWidth: 1)
                                        )
                                }
                            }
                        }
                        
                        ModernButton(
                            title: "Send Message",
                            icon: "paperplane.fill",
                            style: .primary,
                            size: .large,
                            action: {
                                isLoading = true
                                // Simulate sending
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    HapticsManager.shared.success()
                                    dismiss()
                                }
                            },
                            isLoading: isLoading
                        )
                    }
                    .padding(ModernDesign.Spacing.lg)
                }
            }
            .navigationTitle("Contact Support")
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
        }
    }
}
