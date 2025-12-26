import Foundation
import Combine

@MainActor
class WorkerJobsViewModel: ObservableObject {
    @Published var jobs: [Job] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func loadJobs(for workerID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Backend already filters jobs for workers - no client-side filtering needed
            jobs = try await apiService.fetchJobs()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // Compatibility method with different label
    func loadJobs(forWorkerID workerID: String) {
        Task {
            await loadJobs(for: workerID)
        }
    }
    
    var activeJobs: [Job] {
        jobs.filter { $0.status == .active }
    }
    
    var completedJobs: [Job] {
        jobs.filter { $0.status == .completed }
    }
}
