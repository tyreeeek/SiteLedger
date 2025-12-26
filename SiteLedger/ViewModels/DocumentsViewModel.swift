import Foundation
import SwiftUI
import Combine

@MainActor
class DocumentsViewModel: ObservableObject {
    @Published var documents: [Document] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func loadDocuments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            documents = try await apiService.fetchDocuments()
            print("[DocumentsViewModel] ✅ Loaded \(documents.count) documents")
        } catch {
            errorMessage = error.localizedDescription
            print("[DocumentsViewModel] ❌ Error loading documents: \(error)")
        }
        
        isLoading = false
    }
    
    func loadDocuments(userID: String) {
        Task {
            await loadDocuments()
        }
    }
    
    func loadDocuments(for jobID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allDocs = try await apiService.fetchDocuments()
            documents = allDocs.filter { $0.jobID == jobID }
            print("[DocumentsViewModel] ✅ Loaded \(documents.count) documents for job \(jobID)")
        } catch {
            errorMessage = error.localizedDescription
            print("[DocumentsViewModel] ❌ Error loading documents: \(error)")
        }
        
        isLoading = false
    }
    
    func loadDocumentsForJob(jobID: String) {
        Task {
            await loadDocuments(for: jobID)
        }
    }
    
    func processDocumentWithAI(_ document: Document) async {
        // Placeholder for AI document processing
    }
    
    func uploadDocument(_ document: Document, image: UIImage?) async throws {
        // Upload document with optional image
        if let image = image, let docID = document.id {
            let _ = try await apiService.uploadImage(image, type: "document", id: docID)
        }
    }
    
    func uploadDocument(_ image: UIImage, documentID: String) async throws -> String {
        return try await apiService.uploadImage(image, type: "document", id: documentID)
    }
    
    func createDocument(
        ownerID: String,
        jobID: String?,
        name: String,
        type: String,
        fileURL: String?,
        documentCategory: Document.DocumentCategory? = nil,
        notes: String?
    ) async throws {
        // Create document
        let docType: Document.DocumentType = type == "pdf" ? .pdf : (type == "image" ? .image : .other)
        let doc = Document(
            ownerID: ownerID,
            jobID: jobID,
            fileURL: fileURL ?? "",
            fileType: docType,
            title: name,
            notes: notes ?? "",
            documentCategory: documentCategory
        )
        
        // Actually save to backend
        let created = try await apiService.createDocument(doc)
        await MainActor.run {
            documents.append(created)
        }
    }
    
    func deleteDocument(_ document: Document) async throws {
        guard let id = document.id else { return }
        _ = try await apiService.deleteDocument(id: id)
        documents.removeAll { $0.id == document.id }
    }
    
    func documentsForJob(_ jobID: String) -> [Document] {
        documents.filter { $0.jobID == jobID }
    }
}
