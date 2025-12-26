import Foundation
import Combine

@MainActor
class AlertsViewModel: ObservableObject {
    @Published var alerts: [Alert] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showUnreadOnly = false
    @Published var selectedSeverity: AlertSeverity?
    @Published var selectedType: AlertType?
    
    private let apiService = APIService.shared
    
    // MARK: - Computed Properties
    
    var allAlerts: [Alert] {
        alerts
    }
    
    var filteredAlerts: [Alert] {
        var result = alerts
        
        if showUnreadOnly {
            result = result.filter { !$0.read }
        }
        
        if let severity = selectedSeverity {
            result = result.filter { $0.severity == severity }
        }
        
        return result
    }
    
    var unreadCount: Int {
        alerts.filter { !$0.read }.count
    }
    
    var budgetAlerts: [Alert] {
        alerts.filter { $0.type == .budget }
    }
    
    var paymentAlerts: [Alert] {
        alerts.filter { $0.type == .payment }
    }
    
    func alertsBySeverity(_ severity: AlertSeverity) -> [Alert] {
        alerts.filter { $0.severity == severity }
    }
    
    // MARK: - Load Methods
    
    func loadAlerts() async {
        isLoading = true
        errorMessage = nil
        
        // For now, alerts are generated client-side or via API
        // This is a placeholder until alerts endpoint is implemented
        alerts = []
        isLoading = false
    }
    
    func loadAlerts(forOwnerID ownerID: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            // For now, alerts are generated client-side or via API
            // This is a placeholder until alerts endpoint is implemented
            alerts = []
            isLoading = false
        }
    }
    
    // MARK: - Actions
    
    func dismissAlert(_ alert: Alert) async {
        alerts.removeAll { $0.id == alert.id }
    }
    
    func deleteAlert(_ alert: Alert) {
        Task {
            await dismissAlert(alert)
        }
    }
    
    func markAsRead(_ alert: Alert) async {
        if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[index].read = true
        }
    }
    
    func markAllAsRead(ownerID: String) async throws {
        for i in 0..<alerts.count {
            alerts[i].read = true
        }
    }
    
    func deleteReadAlerts() async throws {
        alerts.removeAll { $0.read }
    }
}
