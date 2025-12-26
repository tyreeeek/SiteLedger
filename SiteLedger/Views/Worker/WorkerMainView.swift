import SwiftUI

struct WorkerMainView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0
    @StateObject private var timesheetViewModel = TimesheetViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
            // My Jobs Tab
            WorkerJobsListView()
                .tabItem {
                    Image(systemName: "briefcase.fill")
                    Text("My Jobs")
                }
                .tag(0)
                .onAppear {
                    if !timesheetViewModel.availableJobs.isEmpty { return }
                    Task {
                        guard let userID = authService.currentUser?.id else { return }
                        await timesheetViewModel.loadData(workerID: userID)
                    }
                }
            
            // Check In/Out Tab
            WorkerCheckInView(viewModel: timesheetViewModel)
                .tabItem {
                    Image(systemName: "hourglass.circle.fill")
                    Text("Clock")
                }
                .tag(1)
            
            // My Hours Tab
            WorkerHoursView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("Hours")
                }
                .tag(2)
            
            // More Tab (Profile, Settings, etc.)
            ModernProfileView()
                .tabItem {
                    Image(systemName: "ellipsis.circle.fill")
                    Text("More")
                }
                .tag(3)
            }
            .accentColor(ModernDesign.Colors.primary)
            
            // Connection status banner overlay
            VStack {
                ConnectionStatusBanner()
                Spacer()
            }
        }
    }
}

