import Foundation
import Combine

@MainActor
class WorkersViewModel: ObservableObject {
    @Published var workers: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func loadWorkers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            workers = try await apiService.fetchWorkers()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func inviteWorker(email: String, name: String) async throws {
        // Invite worker via API
        let newWorker = try await apiService.inviteWorker(email: email, name: name)
        
        // Add immediately to list for instant UI update
        workers.append(newWorker)
        
        // Refresh list in background to sync any server changes
        Task {
            await loadWorkers()
        }
    }
    
    func updateWorker(_ worker: User) async throws {
        try await apiService.updateWorker(worker)
        await loadWorkers()
    }
    
    func removeWorker(_ worker: User) async throws {
        guard let id = worker.id else { return }
        _ = try await apiService.deleteWorker(id: id)
        await loadWorkers()
    }
    
    func resetWorkerPassword(workerID: String, newPassword: String) async throws {
        try await apiService.resetWorkerPassword(workerID: workerID, newPassword: newPassword)
    }
    
    func sendInviteEmail(workerID: String) async throws -> (email: String, tempPassword: String) {
        return try await apiService.sendWorkerInvite(workerID: workerID)
    }
    
    func assignWorkerToJob(workerID: String, jobID: String) async throws {
        try await apiService.assignWorkerToJob(workerID: workerID, jobID: jobID)
    }
    
    func unassignWorkerFromJob(workerID: String, jobID: String) async throws {
        try await apiService.unassignWorkerFromJob(workerID: workerID, jobID: jobID)
    }
    
    var activeWorkers: [User] {
        workers.filter { $0.active == true }
    }
}
