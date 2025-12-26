import SwiftUI

struct MoreView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                    // PROFILE CARD AT TOP
                    if let user = authService.currentUser {
                        NavigationLink {
                            ProfileView()
                        } label: {
                            ProfileCard(
                                name: user.name,
                                email: user.email,
                                memberSince: "Member since \(formattedDate(user.createdAt))",
                                role: user.role == .owner ? "Owner" : "Worker",
                                phone: nil,  // Phone field not yet in User model
                                photoURL: user.photoURL,
                                onTap: {}
                            )
                        }
                        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                        .padding(.top, DesignSystem.Spacing.standard)
                    }
                    
                    // ACCOUNT SECTION
                    SettingsSection("ACCOUNT") {
                        NavigationLink {
                            ProfileView()
                        } label: {
                            SettingsRow(
                                icon: "person.crop.circle",
                                iconColor: DesignSystem.Colors.primary,
                                title: "My Profile",
                                subtitle: "View and edit profile"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink {
                            AccountSettingsView()
                        } label: {
                            SettingsRow(
                                icon: "lock.fill",
                                iconColor: DesignSystem.Colors.purple,
                                title: "Account & Security",
                                subtitle: "Password, login methods"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                    
                    // TEAM SECTION
                    SettingsSection("TEAM") {
                        NavigationLink {
                            WorkersListView()
                        } label: {
                            SettingsRow(
                                icon: "person.2.fill",
                                iconColor: DesignSystem.Colors.blue,
                                title: "Workers",
                                subtitle: "Manage team members"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink {
                            AllTimesheetsView()
                        } label: {
                            SettingsRow(
                                icon: "clock.badge",
                                iconColor: DesignSystem.Colors.teal,
                                title: "All Workers' Hours",
                                subtitle: "Team hours across jobs"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                    
                    // INSIGHTS & ALERTS SECTION
                    SettingsSection("INSIGHTS & ALERTS") {
                        NavigationLink {
                            AIInsightsView()
                        } label: {
                            SettingsRow(
                                icon: "sparkles",
                                iconColor: DesignSystem.Colors.primary,
                                title: "AI Insights",
                                subtitle: "Business recommendations"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink {
                            AlertHistoryView()
                        } label: {
                            SettingsRow(
                                icon: "exclamationmark.bubble.fill",
                                iconColor: DesignSystem.Colors.orange,
                                title: "Alert History",
                                subtitle: "View all past alerts"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink {
                            NotificationSettingsView()
                        } label: {
                            SettingsRow(
                                icon: "bell.fill",
                                iconColor: DesignSystem.Colors.pink,
                                title: "Notifications",
                                subtitle: "Manage alert preferences"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                    
                    // APP SECTION
                    SettingsSection("APP") {
                        NavigationLink {
                            AppSettingsView()
                        } label: {
                            SettingsRow(
                                icon: "gearshape.fill",
                                iconColor: DesignSystem.Colors.cyan,
                                title: "General Settings",
                                subtitle: "Display, data & more"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                    
                    // HELP & LEGAL SECTION
                    SettingsSection("HELP & LEGAL") {
                        NavigationLink {
                            FAQView()
                        } label: {
                            SettingsRow(
                                icon: "book.fill",
                                iconColor: DesignSystem.Colors.blue,
                                title: "FAQ",
                                subtitle: "Frequently asked questions"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink {
                            SupportView()
                        } label: {
                            SettingsRow(
                                icon: "envelope.fill",
                                iconColor: DesignSystem.Colors.purple,
                                title: "Support",
                                subtitle: "Contact our team"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink {
                            LegalView(legalType: .privacy)
                        } label: {
                            SettingsRow(
                                icon: "lock.doc.fill",
                                iconColor: DesignSystem.Colors.green,
                                title: "Privacy & Terms",
                                subtitle: "Legal information"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                    
                    // SIGN OUT BUTTON
                    Button {
                        HapticsManager.shared.medium()
                        showSignOutAlert = true
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.small) {
                            Image(systemName: "power.circle.fill")
                            Text("Sign Out")
                        }
                        .font(DesignSystem.TextStyle.buttonLabel)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignSystem.Layout.buttonHeight)
                        .background(DesignSystem.Colors.destructive)
                        .cornerRadius(DesignSystem.Layout.buttonRadius)
                        .shadow(
                            color: DesignSystem.Shadow.color,
                            radius: DesignSystem.Shadow.radius,
                            x: DesignSystem.Shadow.x,
                            y: DesignSystem.Shadow.y
                        )
                    }
                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                    .padding(.top, DesignSystem.Spacing.small)
                    
                    Spacer(minLength: DesignSystem.Spacing.extraLarge)
                }
                .padding(.bottom, DesignSystem.Spacing.sectionSpacing)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out?", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {
                    HapticsManager.shared.light()
                }
                Button("Sign Out", role: .destructive) {
                    HapticsManager.shared.medium()
                    authService.signOut()
                }
            } message: {
                Text("You will need to sign in again to access your account.")
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    MoreView()
        .environmentObject(AuthService())
}
