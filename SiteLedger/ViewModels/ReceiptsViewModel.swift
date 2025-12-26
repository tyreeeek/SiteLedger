import Foundation
import SwiftUI
import Combine

@MainActor
class ReceiptsViewModel: ObservableObject {
    @Published var receipts: [Receipt] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func loadReceipts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            receipts = try await apiService.fetchReceipts()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadReceipts(for jobID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allReceipts = try await apiService.fetchReceipts()
            receipts = allReceipts.filter { $0.jobID == jobID }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createReceipt(_ receipt: Receipt) async throws {
        try await apiService.createReceipt(receipt)
        await loadReceipts()
    }
    
    func updateReceipt(_ receipt: Receipt) async throws {
        try await apiService.updateReceipt(receipt)
        await loadReceipts()
    }
    
    func deleteReceipt(_ receipt: Receipt) async throws {
        guard let id = receipt.id else { return }
        _ = try await apiService.deleteReceipt(id: id)
        await loadReceipts()
    }
    
    func uploadReceiptImage(_ image: UIImage, receiptID: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ReceiptsViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        let filename = "\(receiptID).jpg"
        let response = try await apiService.uploadReceipt(imageData: imageData, filename: filename)
        return response.url
    }
    
    // Alias for views using userID parameter
    func loadReceipts(userID: String) {
        Task {
            await loadReceipts()
        }
    }
    
    // Receipt statistics
    var totalReceiptAmount: Double {
        receipts.reduce(0) { $0 + ($1.amount ?? 0) }
    }
    
    func receiptsForJob(_ jobID: String) -> [Receipt] {
        receipts.filter { $0.jobID == jobID }
    }
}
