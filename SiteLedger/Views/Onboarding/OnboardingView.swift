import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "briefcase.fill",
            title: "Manage Your Jobs",
            description: "Create and track all your contractor jobs in one place. Set project values, assign workers, and monitor progress from start to finish.",
            color: DesignSystem.Colors.primary
        ),
        OnboardingPage(
            image: "clock.fill",
            title: "Track Time & Labor",
            description: "Workers can clock in and out with GPS verification. Automatically calculate labor costs based on hourly rates and hours worked.",
            color: Color.orange
        ),
        OnboardingPage(
            image: "doc.text.fill",
            title: "Store Receipts & Documents",
            description: "Snap photos of receipts and documents. Our AI automatically extracts vendor, amount, and date information for easy organization.",
            color: Color.green
        ),
        OnboardingPage(
            image: "chart.line.uptrend.xyaxis",
            title: "See Your Profits",
            description: "Real-time profit calculations show you exactly how much you're making. Profit = Project Value - Labor Costs. Simple and clear.",
            color: Color.purple
        ),
        OnboardingPage(
            image: "person.2.fill",
            title: "Manage Your Team",
            description: "Add workers, assign them to jobs, track their hours, and manage payroll all in one app. Everyone stays on the same page.",
            color: Color.blue
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    pages[currentPage].color.opacity(0.15),
                    DesignSystem.Colors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(DesignSystem.TextStyle.bodyPrimary)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding()
                    }
                }
                .frame(height: 50)
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? pages[currentPage].color : Color.gray.opacity(0.3))
                            .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 30)
                
                // Bottom buttons
                VStack(spacing: 16) {
                    if currentPage == pages.count - 1 {
                        // Final page - Get Started button
                        Button {
                            HapticsManager.shared.success()
                            completeOnboarding()
                        } label: {
                            Text("Get Started")
                                .font(DesignSystem.TextStyle.buttonLabel)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: DesignSystem.Layout.buttonHeight)
                                .background(DesignSystem.Colors.primary)
                                .cornerRadius(DesignSystem.Layout.buttonRadius)
                        }
                    } else {
                        // Next button
                        Button {
                            HapticsManager.shared.light()
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            Text("Next")
                                .font(DesignSystem.TextStyle.buttonLabel)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: DesignSystem.Layout.buttonHeight)
                                .background(pages[currentPage].color)
                                .cornerRadius(DesignSystem.Layout.buttonRadius)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                .padding(.bottom, 50)
            }
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(page.color.opacity(0.25))
                    .frame(width: 120, height: 120)
                
                Image(systemName: page.image)
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(page.color)
            }
            
            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(DesignSystem.TextStyle.bodyPrimary)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
    }
}

#Preview {
    OnboardingView()
}
