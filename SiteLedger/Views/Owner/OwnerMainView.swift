import SwiftUI

struct OwnerMainView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("defaultTab") private var defaultTab = 0
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
            // Dashboard Tab
            ModernDashboardView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            // Jobs Tab
            ModernJobsListView()
                .tabItem {
                    Image(systemName: "briefcase.fill")
                    Text("Jobs")
                }
                .tag(1)
            
            // Receipts Tab
            ModernReceiptsListView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Receipts")
                }
                .tag(2)
            
            // Documents Tab
            ModernDocumentsListView()
                .tabItem {
                    Image(systemName: "doc.fill")
                    Text("Documents")
                }
                .tag(3)
            
            // More Tab
            ModernProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("More")
                }
                .tag(4)
            }
            .accentColor(ModernDesign.Colors.primary)
            .onAppear {
                // Set initial tab from user preferences
                selectedTab = defaultTab
            }
            
            // Connection status banner overlay
            VStack {
                ConnectionStatusBanner()
                Spacer()
            }
        }
    }
}

#Preview {
    OwnerMainView()
        .environmentObject(AuthService())
}
