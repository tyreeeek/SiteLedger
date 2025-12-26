import SwiftUI

struct WorkerTabView: View {
    @EnvironmentObject var authService: AuthService
    @State private var unreadCount = 0
    @StateObject private var timesheetViewModel = TimesheetViewModel()
    
    var body: some View {
        TabView {
            WorkerJobsView()
                .tabItem {
                    Image(systemName: "briefcase")
                    Text("My Jobs")
                }
            
            WorkerCheckInView(viewModel: timesheetViewModel)
                .tabItem {
                    Image(systemName: "clock")
                    Text("Check In/Out")
                }
            
            WorkerHoursView()
                .tabItem {
                    Image(systemName: "timer")
                    Text("My Hours")
                }
            
            NotificationsView()
                .tabItem {
                    Image(systemName: unreadCount > 0 ? "bell.badge.fill" : "bell")
                    Text("Notifications")
                }
                .badge(unreadCount > 0 ? unreadCount : 0)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
    }
}

struct WorkerJobsView: View {
    @StateObject private var viewModel = TimesheetViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.availableJobs) { job in
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.jobName)
                        .font(.headline)
                    Text(job.clientName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(job.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("My Jobs")
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
}

// HoursSummaryCard moved to WorkerHoursView.swift

struct HoursSummaryCard: View {
    let title: String
    let hours: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(hours, specifier: "%.1f")h")
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}