import SwiftUI
import Combine

/// View for owners to review and approve pending timesheets
struct TimesheetApprovalView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = TimesheetViewModel()
    @State private var selectedStatus: String = "pending"
    
    var filteredTimesheets: [Timesheet] {
        viewModel.timesheets.filter { $0.status == selectedStatus }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status Filter
                Picker("Status", selection: $selectedStatus) {
                    Text("Pending").tag("pending")
                    Text("Approved").tag("approved")
                    Text("Rejected").tag("rejected")
                }
                .pickerStyle(.segmented)
                .padding()
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading timesheets...")
                    Spacer()
                } else if filteredTimesheets.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No \(selectedStatus) timesheets")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredTimesheets, id: \.id) { timesheet in
                            TimesheetApprovalRow(
                                timesheet: timesheet,
                                onApprove: { approveTimesheet(timesheet) },
                                onReject: { rejectTimesheet(timesheet) }
                            )
                            .id(timesheet.id ?? UUID().uuidString)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Approve Timesheets")
            .onAppear {
                Task {
                    await viewModel.loadData()
                }
            }
        }
    }
    
    private func approveTimesheet(_ timesheet: Timesheet) {
        Task {
            var updated = timesheet
            updated.status = "approved"
            try? await viewModel.updateTimesheet(updated)
        }
    }
    
    private func rejectTimesheet(_ timesheet: Timesheet) {
        Task {
            var updated = timesheet
            updated.status = "rejected"
            try? await viewModel.updateTimesheet(updated)
        }
    }
}

struct TimesheetApprovalRow: View {
    let timesheet: Timesheet
    let onApprove: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Worker: \(timesheet.userID ?? "Unknown")")
                        .font(.headline)
                    
                    if let clockIn = timesheet.clockIn {
                        Text("Date: \(clockIn, style: .date)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Hours: \(String(format: "%.2f", timesheet.hours ?? 0))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if timesheet.status == "pending" {
                    HStack(spacing: 12) {
                        Button(action: onReject) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: onApprove) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text(timesheet.status?.capitalized ?? "")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(timesheet.status == "approved" ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .foregroundColor(timesheet.status == "approved" ? .green : .red)
                        .cornerRadius(8)
                }
            }
            
            if let notes = timesheet.notes, !notes.isEmpty {
                Text("Notes: \(notes)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
