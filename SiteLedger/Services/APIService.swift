import Foundation
import UIKit

/// API Service - DigitalOcean PostgreSQL backend
actor APIService {
    static let shared = APIService()
    
    // MARK: - Configuration
    
    /// Backend API URL - Production DigitalOcean server with HTTPS
    private let baseURL = "https://api.siteledger.ai/api"
    
    /// Stored JWT token
    private var accessToken: String?
    
    /// URLSession with custom configuration for better connection handling
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30 // 30 seconds for request
        config.timeoutIntervalForResource = 60 // 60 seconds for resource download
        config.waitsForConnectivity = true // Wait for connectivity instead of failing immediately
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()
    
    /// Maximum retry attempts for failed requests
    private let maxRetries = 3
    
    /// Delay between retry attempts (in seconds)
    private let retryDelay: TimeInterval = 2.0
    
    /// Connection status
    private var isConnected: Bool = true
    
    /// Last successful connection timestamp
    private var lastSuccessfulConnection: Date?
    
    private init() {}
    
    // MARK: - Connection Health
    
    /// Check server health and connectivity
    func checkHealth() async -> Bool {
        do {
            // Use the correct health endpoint
            let healthURL = "https://api.siteledger.ai/health"
            guard let url = URL(string: healthURL) else {
                return false
            }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 5.0
            
            let (_, response) = try await urlSession.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                await updateConnectionStatus(true)
                return true
            }
            
            await updateConnectionStatus(false)
            return false
        } catch {
            print("[APIService] Health check failed: \(error.localizedDescription)")
            await updateConnectionStatus(false)
            return false
        }
    }
    
    /// Update connection status
    private func updateConnectionStatus(_ connected: Bool) async {
        isConnected = connected
        if connected {
            lastSuccessfulConnection = Date()
        }
    }
    
    /// Get current connection status
    func getConnectionStatus() -> Bool {
        return isConnected
    }
    
    // MARK: - Token Management
    
    func setAccessToken(_ token: String) {
        self.accessToken = token
        // Persist token
        UserDefaults.standard.set(token, forKey: "api_access_token")
    }
    
    func loadStoredToken() {
        self.accessToken = UserDefaults.standard.string(forKey: "api_access_token")
    }
    
    func clearToken() {
        self.accessToken = nil
        UserDefaults.standard.removeObject(forKey: "api_access_token")
    }
    
    // MARK: - Network Layer
    
    /// Execute request with retry logic for better connection resilience
    private func request<T: Decodable>(
        _ method: String,
        path: String,
        body: [String: Any]? = nil,
        retryCount: Int = 0
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        
        if let token = accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                // Debug logging for JSON decoding issues
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[APIService] Response JSON: \(jsonString)")
                } else {
                    print("[APIService] Failed to convert data to string")
                }
                
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    print("[APIService] JSON Decoding Error: \(error)")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("[APIService] Key '\(key.stringValue)' not found: \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("[APIService] Type mismatch for \(type): \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("[APIService] Value not found for \(type): \(context.debugDescription)")
                        case .dataCorrupted(let context):
                            print("[APIService] Data corrupted: \(context.debugDescription)")
                        @unknown default:
                            print("[APIService] Unknown decoding error: \(error)")
                        }
                    }
                    throw error
                }
            case 401:
                // Try to get specific error message from response (e.g., "Current password is incorrect")
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.message)
                }
                throw APIError.unauthorized
            case 403:
                throw APIError.forbidden
            case 404:
                throw APIError.notFound
            default:
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.message)
                }
                throw APIError.serverError("Request failed with status \(httpResponse.statusCode)")
            }
        } catch let urlError as URLError {
            // Handle network errors with retry logic
            let shouldRetry = shouldRetryForError(urlError) && retryCount < maxRetries
            
            if shouldRetry {
                print("[APIService] Network error (attempt \(retryCount + 1)/\(maxRetries)): \(urlError.localizedDescription)")
                print("[APIService] Retrying in \(retryDelay) seconds...")
                
                // Wait before retrying
                try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                
                // Retry the request
                return try await request(method, path: path, body: body, retryCount: retryCount + 1)
            } else {
                print("[APIService] Network error (final): \(urlError.localizedDescription)")
                throw APIError.networkError(urlError.localizedDescription)
            }
        }
    }
    
    /// Determine if an error is retryable
    private func shouldRetryForError(_ error: URLError) -> Bool {
        switch error.code {
        case .timedOut,
             .cannotConnectToHost,
             .networkConnectionLost,
             .notConnectedToInternet,
             .dnsLookupFailed,
             .cannotFindHost:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Auth Endpoints
    
    struct AuthResponse: Codable {
        let user: APIUser
        let accessToken: String
    }
    
    struct APIUser: Codable {
        let id: String
        let email: String
        let name: String
        let role: String
        let active: Bool
        let hourlyRate: Double?
        let phone: String?
        let photoURL: String?
        let ownerId: String?
        let assignedJobIDs: [String]?
        let createdAt: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case email
            case name
            case role
            case active
            case hourlyRate
            case phone
            case photoURL
            case ownerId
            case assignedJobIDs
            case createdAt
        }
        
        // Custom decoder to handle missing optional fields gracefully
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            id = try container.decode(String.self, forKey: .id)
            email = try container.decode(String.self, forKey: .email)
            name = try container.decode(String.self, forKey: .name)
            role = try container.decode(String.self, forKey: .role)
            active = try container.decode(Bool.self, forKey: .active)
            createdAt = try container.decode(String.self, forKey: .createdAt)
            
            // Handle hourlyRate as either String or Double (backend sends as string)
            if let hourlyRateString = try? container.decodeIfPresent(String.self, forKey: .hourlyRate) {
                hourlyRate = Double(hourlyRateString)
            } else {
                hourlyRate = try container.decodeIfPresent(Double.self, forKey: .hourlyRate)
            }
            
            // Optional fields - use decodeIfPresent to handle missing fields
            phone = try container.decodeIfPresent(String.self, forKey: .phone)
            photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
            ownerId = try container.decodeIfPresent(String.self, forKey: .ownerId)
            assignedJobIDs = try container.decodeIfPresent([String].self, forKey: .assignedJobIDs)
        }
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let response: AuthResponse = try await request("POST", path: "/auth/login", body: [
            "email": email,
            "password": password
        ])
        setAccessToken(response.accessToken)
        return response
    }
    
    func signup(email: String, password: String, name: String, role: String = "owner") async throws -> AuthResponse {
        let response: AuthResponse = try await request("POST", path: "/auth/signup", body: [
            "email": email,
            "password": password,
            "name": name,
            "role": role
        ])
        setAccessToken(response.accessToken)
        return response
    }
    
    func getCurrentUser() async throws -> APIUser {
        return try await request("GET", path: "/auth/me")
    }
    
    func updateProfile(name: String?, phone: String?, photoURL: String?) async throws -> APIUser {
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        if let phone = phone { body["phone"] = phone }
        if let photoURL = photoURL { body["photoURL"] = photoURL }
        return try await request("PUT", path: "/auth/profile", body: body)
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        let _: EmptyResponse = try await request("POST", path: "/auth/change-password", body: [
            "currentPassword": currentPassword,
            "newPassword": newPassword
        ])
    }
    
    func changeEmail(newEmail: String, password: String) async throws -> ChangeEmailResponse {
        return try await request("POST", path: "/auth/change-email", body: [
            "newEmail": newEmail,
            "password": password
        ])
    }
    
    struct ChangeEmailResponse: Codable {
        let message: String
        let newEmail: String
    }
    
    func loginWithApple(identityToken: String, authorizationCode: String, fullName: String?, email: String?, appleUserID: String) async throws -> AuthResponse {
        var body: [String: Any] = [
            "identityToken": identityToken,
            "authorizationCode": authorizationCode,
            "appleUserID": appleUserID
        ]
        if let fullName = fullName { body["fullName"] = fullName }
        if let email = email { body["email"] = email }
        
        let response: AuthResponse = try await request("POST", path: "/auth/apple", body: body)
        setAccessToken(response.accessToken)
        return response
    }
    
    
    
    func forgotPassword(email: String) async throws -> MessageResponse {
        return try await request("POST", path: "/auth/forgot-password", body: [
            "email": email
        ])
    }
    
    func confirmResetPassword(token: String, newPassword: String) async throws -> MessageResponse {
        return try await request("POST", path: "/auth/reset-password", body: [
            "token": token,
            "newPassword": newPassword
        ])
    }
    
    func deleteAccount() async throws {
        let _: MessageResponse = try await request("DELETE", path: "/auth/account")
    }
    
    func resetAllData() async throws {
        let _: MessageResponse = try await request("POST", path: "/auth/reset-all-data")
    }
    
    struct EmptyResponse: Codable {}
    
    // MARK: - Jobs Endpoints
    
    struct APIJob: Codable {
        let id: String
        let ownerID: String
        let jobName: String
        let clientName: String
        let address: String
        let latitude: Double?
        let longitude: Double?
        let status: String
        let phase: String?
        let startDate: String
        let endDate: String?
        let notes: String
        let projectValue: Double
        let amountPaid: Double
        let laborCost: Double?
        let profit: Double?
        let remainingBalance: Double?
        let assignedWorkers: [String]?
        let createdAt: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case ownerID
            case jobName
            case clientName
            case address
            case latitude
            case longitude
            case status
            case phase
            case startDate
            case endDate
            case notes
            case projectValue
            case amountPaid
            case laborCost
            case profit
            case remainingBalance
            case assignedWorkers
            case createdAt
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            ownerID = try container.decode(String.self, forKey: .ownerID)
            jobName = try container.decode(String.self, forKey: .jobName)
            clientName = try container.decode(String.self, forKey: .clientName)
            address = try container.decode(String.self, forKey: .address)
            latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
            longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
            status = try container.decode(String.self, forKey: .status)
            phase = try container.decodeIfPresent(String.self, forKey: .phase)
            startDate = try container.decode(String.self, forKey: .startDate)
            endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
            notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
            projectValue = try container.decode(Double.self, forKey: .projectValue)
            amountPaid = try container.decode(Double.self, forKey: .amountPaid)
            laborCost = try container.decodeIfPresent(Double.self, forKey: .laborCost)
            profit = try container.decodeIfPresent(Double.self, forKey: .profit)
            remainingBalance = try container.decodeIfPresent(Double.self, forKey: .remainingBalance)
            assignedWorkers = try container.decodeIfPresent([String].self, forKey: .assignedWorkers)
            createdAt = try container.decode(String.self, forKey: .createdAt)
        }
    }
    
    func getJobs() async throws -> [APIJob] {
        return try await request("GET", path: "/jobs")
    }
    
    func getJob(id: String) async throws -> APIJob {
        return try await request("GET", path: "/jobs/\(id)")
    }
    
    func createJob(_ job: [String: Any]) async throws -> APIJob {
        return try await request("POST", path: "/jobs", body: job)
    }
    
    func updateJob(id: String, updates: [String: Any]) async throws -> APIJob {
        return try await request("PUT", path: "/jobs/\(id)", body: updates)
    }
    
    func deleteJob(id: String) async throws -> MessageResponse {
        return try await request("DELETE", path: "/jobs/\(id)")
    }
    
    // MARK: - Receipts Endpoints
    
    struct APIReceipt: Codable {
        let id: String
        let ownerID: String
        let jobID: String?
        let amount: Double
        let vendor: String
        let category: String?
        let date: String
        let imageURL: String?
        let notes: String?
        let aiProcessed: Bool?
        let aiConfidence: Double?
        let aiFlags: [String]?
        let aiSuggestedCategory: String?
        let createdAt: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case ownerID
            case jobID
            case amount
            case vendor
            case category
            case date
            case imageURL
            case notes
            case aiProcessed
            case aiConfidence
            case aiFlags
            case aiSuggestedCategory
            case createdAt
        }
    }
    
    func getReceipts() async throws -> [APIReceipt] {
        return try await request("GET", path: "/receipts")
    }
    
    func createReceipt(_ receipt: [String: Any]) async throws -> APIReceipt {
        return try await request("POST", path: "/receipts", body: receipt)
    }
    
    func deleteReceipt(id: String) async throws -> MessageResponse {
        return try await request("DELETE", path: "/receipts/\(id)")
    }
    
    // MARK: - Timesheets Endpoints
    
    struct APITimesheet: Codable {
        let id: String
        let ownerID: String
        let workerID: String
        let workerName: String?
        let jobID: String
        let jobName: String?
        let clockIn: String
        let clockOut: String?
        let hours: Double?
        let effectiveHours: Double?
        let status: String
        let notes: String?
        let createdAt: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case ownerID
            case workerID
            case workerName
            case jobID
            case jobName
            case clockIn
            case clockOut
            case hours
            case effectiveHours
            case status
            case notes
            case createdAt
        }
    }
    
    func getTimesheets() async throws -> [APITimesheet] {
        return try await request("GET", path: "/timesheets")
    }
    
    func getActiveTimesheet() async throws -> APITimesheet? {
        return try await request("GET", path: "/timesheets/active")
    }
    
    func clockIn(jobID: String, latitude: Double?, longitude: Double?, location: String?) async throws -> APITimesheet {
        var body: [String: Any] = ["jobID": jobID]
        if let lat = latitude { body["latitude"] = lat }
        if let lng = longitude { body["longitude"] = lng }
        if let loc = location { body["location"] = loc }
        print("🔶 ClockIn API call with jobID: \(jobID)")
        do {
            let result: APITimesheet = try await request("POST", path: "/timesheets/clock-in", body: body)
            print("🔶 ClockIn SUCCESS: \(result.id)")
            return result
        } catch {
            print("🔶 ClockIn FAILED: \(error)")
            throw error
        }
    }
    
    func clockOut(latitude: Double?, longitude: Double?, location: String?, notes: String?) async throws -> APITimesheet {
        var body: [String: Any] = [:]
        if let lat = latitude { body["latitude"] = lat }
        if let lng = longitude { body["longitude"] = lng }
        if let loc = location { body["location"] = loc }
        if let notes = notes { body["notes"] = notes }
        return try await request("POST", path: "/timesheets/clock-out", body: body)
    }
    
    // MARK: - Workers Endpoints
    
    func getWorkers() async throws -> [APIUser] {
        return try await request("GET", path: "/workers")
    }
    
    func createWorker(_ worker: [String: Any]) async throws -> APIUser {
        return try await request("POST", path: "/workers", body: worker)
    }
    
    func updateWorker(id: String, updates: [String: Any]) async throws -> APIUser {
        return try await request("PUT", path: "/workers/\(id)", body: updates)
    }
    
    func deleteWorker(id: String) async throws -> MessageResponse {
        return try await request("DELETE", path: "/workers/\(id)")
    }
    
    func resetWorkerPassword(workerID: String, newPassword: String) async throws {
        struct PasswordResetResponse: Codable {
            let message: String
        }
        let _: PasswordResetResponse = try await request("POST", path: "/workers/\(workerID)/reset-password", body: [
            "newPassword": newPassword
        ])
    }
    
    func sendWorkerInvite(workerID: String) async throws -> (email: String, tempPassword: String) {
        struct InviteResponse: Codable {
            let message: String
            let email: String
            let tempPassword: String
        }
        let response: InviteResponse = try await request("POST", path: "/workers/\(workerID)/send-invite")
        return (response.email, response.tempPassword)
    }
    
    // MARK: - Upload Endpoints
    
    func uploadReceipt(imageData: Data, filename: String) async throws -> UploadResponse {
        return try await uploadFile(data: imageData, filename: filename, endpoint: "/upload/receipt")
    }
    
    func uploadDocument(fileData: Data, filename: String) async throws -> UploadResponse {
        return try await uploadFile(data: fileData, filename: filename, endpoint: "/upload/document")
    }
    
    func uploadProfilePhoto(imageData: Data, filename: String) async throws -> UploadResponse {
        return try await uploadFile(data: imageData, filename: filename, endpoint: "/upload/profile")
    }
    
    private func uploadFile(data: Data, filename: String, endpoint: String) async throws -> UploadResponse {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // 30 second timeout for uploads (increased for slower connections)
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Build multipart form data
        var body = Data()
        
        // Add file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        
        // Detect content type from filename
        let contentType: String
        if filename.lowercased().hasSuffix(".jpg") || filename.lowercased().hasSuffix(".jpeg") {
            contentType = "image/jpeg"
        } else if filename.lowercased().hasSuffix(".png") {
            contentType = "image/png"
        } else if filename.lowercased().hasSuffix(".heic") {
            contentType = "image/heic"
        } else if filename.lowercased().hasSuffix(".pdf") {
            contentType = "application/pdf"
        } else {
            contentType = "application/octet-stream"
        }
        
        body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.uploadFailed
        }
        
        // Log error details if upload fails
        if httpResponse.statusCode != 200 {
            let errorString = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            print("❌ Upload failed (\(httpResponse.statusCode)): \(errorString)")
            throw APIError.serverError("Upload failed: \(errorString)")
        }
        
        return try JSONDecoder().decode(UploadResponse.self, from: responseData)
    }
    
    // MARK: - Response Types
    
    struct MessageResponse: Codable {
        let message: String
        let resetToken: String?           // Development: password reset token
        let expiresIn: String?            // Development: token expiry time
        let testInstructions: String?     // Development: how to use the token
    }
    
    struct UploadResponse: Codable {
        let url: String
    }
    
    struct ErrorResponse: Codable {
        let error: String?
        let errors: [ValidationError]?
        
        struct ValidationError: Codable {
            let msg: String
            let param: String?
        }
        
        var message: String {
            if let error = error {
                return error
            }
            if let errors = errors, !errors.isEmpty {
                return errors.map { $0.msg }.joined(separator: ". ")
            }
            return "An error occurred"
        }
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case uploadFailed
    case networkError(String)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Please log in again"
        case .forbidden:
            return "You don't have permission"
        case .notFound:
            return "Resource not found"
        case .uploadFailed:
            return "File upload failed"
        case .networkError(let message):
            return "Network connection issue: \(message)"
        case .serverError(let message):
            return message
        }
    }
}

// MARK: - Convenience Methods for ViewModels

@MainActor
extension APIService {
    
    // MARK: - Jobs
    
    func fetchJobs() async throws -> [Job] {
        let apiJobs = try await getJobs()
        return apiJobs.map { apiJob in
            var job = Job(
                ownerID: apiJob.ownerID,
                jobName: apiJob.jobName,
                clientName: apiJob.clientName,
                address: apiJob.address,
                latitude: apiJob.latitude,
                longitude: apiJob.longitude,
                startDate: ISO8601DateFormatter().date(from: apiJob.startDate) ?? Date(),
                endDate: apiJob.endDate.flatMap { ISO8601DateFormatter().date(from: $0) },
                status: Job.JobStatus(rawValue: apiJob.status) ?? .active,
                notes: apiJob.notes,
                createdAt: ISO8601DateFormatter().date(from: apiJob.createdAt) ?? Date(),
                projectValue: apiJob.projectValue,
                amountPaid: apiJob.amountPaid
            )
            job.id = apiJob.id  // ✅ SET THE ID!
            job.assignedWorkers = apiJob.assignedWorkers
            return job
        }
    }
    
    func createJob(_ job: Job) async throws {
        let dateFormatter = ISO8601DateFormatter()
        var body: [String: Any] = [
            "ownerID": job.ownerID,
            "jobName": job.jobName,
            "clientName": job.clientName,
            "address": job.address,
            "startDate": dateFormatter.string(from: job.startDate),
            "status": job.status.rawValue,
            "notes": job.notes,
            "projectValue": job.projectValue,
            "amountPaid": job.amountPaid
        ]
        if let lat = job.latitude { body["latitude"] = lat }
        if let lng = job.longitude { body["longitude"] = lng }
        if let endDate = job.endDate { body["endDate"] = dateFormatter.string(from: endDate) }
        
        _ = try await createJob(body)
    }
    
    func updateJob(_ job: Job) async throws {
        guard let id = job.id else { return }
        let dateFormatter = ISO8601DateFormatter()
        var body: [String: Any] = [
            "jobName": job.jobName,
            "clientName": job.clientName,
            "address": job.address,
            "startDate": dateFormatter.string(from: job.startDate),
            "status": job.status.rawValue,
            "notes": job.notes,
            "projectValue": job.projectValue,
            "amountPaid": job.amountPaid
        ]
        if let lat = job.latitude { body["latitude"] = lat }
        if let lng = job.longitude { body["longitude"] = lng }
        if let endDate = job.endDate { body["endDate"] = dateFormatter.string(from: endDate) }
        
        _ = try await updateJob(id: id, updates: body)
    }
    
    // MARK: - Receipts
    
    func fetchReceipts() async throws -> [Receipt] {
        let apiReceipts = try await getReceipts()
        return apiReceipts.map { apiReceipt in
            var receipt = Receipt()
            receipt.id = apiReceipt.id
            receipt.ownerID = apiReceipt.ownerID
            receipt.jobID = apiReceipt.jobID
            receipt.amount = apiReceipt.amount
            receipt.vendor = apiReceipt.vendor
            receipt.category = apiReceipt.category
            receipt.date = ISO8601DateFormatter().date(from: apiReceipt.date) ?? Date()
            receipt.imageURL = apiReceipt.imageURL
            receipt.notes = apiReceipt.notes
            receipt.createdAt = ISO8601DateFormatter().date(from: apiReceipt.createdAt) ?? Date()
            return receipt
        }
    }
    
    func createReceipt(_ receipt: Receipt) async throws {
        let dateFormatter = ISO8601DateFormatter()
        var body: [String: Any] = [
            "ownerID": receipt.ownerID ?? "",
            "amount": receipt.amount ?? 0,
            "vendor": receipt.vendor ?? "",
            "notes": receipt.notes ?? "",
            "date": dateFormatter.string(from: receipt.date ?? Date())
        ]
        if let jobID = receipt.jobID { body["jobID"] = jobID }
        if let category = receipt.category { body["category"] = category }
        if let imageURL = receipt.imageURL { body["imageURL"] = imageURL }
        
        _ = try await createReceipt(body)
    }
    
    func updateReceipt(_ receipt: Receipt) async throws {
        // For now, delete and recreate (API may need update endpoint)
        if let id = receipt.id {
            _ = try await deleteReceipt(id: id)
        }
        try await createReceipt(receipt)
    }
    
    // MARK: - Documents
    
    func createDocument(_ document: Document) async throws -> Document {
        let dateFormatter = ISO8601DateFormatter()
        var body: [String: Any] = [
            "ownerID": document.ownerID,
            "fileURL": document.fileURL,
            "fileType": document.fileType.rawValue,
            "title": document.title,
            "notes": document.notes,
            "createdAt": dateFormatter.string(from: document.createdAt)
        ]
        if let jobID = document.jobID { body["jobID"] = jobID }
        if let category = document.documentCategory { body["documentCategory"] = category.rawValue }
        
        struct CreateDocumentResponse: Codable {
            let id: String
            let ownerID: String
            let jobID: String?
            let fileURL: String
            let fileType: String
            let title: String
            let notes: String
            let documentCategory: String?
            let createdAt: String
        }
        
        let response: CreateDocumentResponse = try await request("POST", path: "/documents", body: body)
        
        var created = document
        created.id = response.id
        return created
    }
    
    func fetchDocuments() async throws -> [Document] {
        struct APIDocument: Codable {
            let id: String
            let ownerID: String
            let jobID: String?
            let fileURL: String
            let fileType: String
            let title: String
            let notes: String
            let documentCategory: String?
            let aiProcessed: Bool?
            let aiSummary: String?
            let aiConfidence: Double?
            let createdAt: String
        }
        
        let apiDocs: [APIDocument] = try await request("GET", path: "/documents")
        
        return apiDocs.map { apiDoc in
            let fileType: Document.DocumentType
            switch apiDoc.fileType.lowercased() {
            case "pdf": fileType = .pdf
            case "image": fileType = .image
            default: fileType = .other
            }
            
            let category: Document.DocumentCategory?
            if let cat = apiDoc.documentCategory {
                category = Document.DocumentCategory(rawValue: cat)
            } else {
                category = nil
            }
            
            var doc = Document(
                ownerID: apiDoc.ownerID,
                jobID: apiDoc.jobID,
                fileURL: apiDoc.fileURL,
                fileType: fileType,
                title: apiDoc.title,
                notes: apiDoc.notes,
                documentCategory: category
            )
            doc.id = apiDoc.id
            doc.aiProcessed = apiDoc.aiProcessed ?? false
            doc.aiSummary = apiDoc.aiSummary
            doc.aiConfidence = apiDoc.aiConfidence
            doc.createdAt = ISO8601DateFormatter().date(from: apiDoc.createdAt) ?? Date()
            return doc
        }
    }
    
    func deleteDocument(id: String) async throws -> MessageResponse {
        return try await request("DELETE", path: "/documents/\(id)")
    }
    
    // MARK: - Timesheets
    
    func fetchTimesheets() async throws -> [Timesheet] {
        let apiTimesheets = try await getTimesheets()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return apiTimesheets.map { apiTimesheet in
            var timesheet = Timesheet()
            timesheet.id = apiTimesheet.id
            timesheet.ownerID = apiTimesheet.ownerID
            timesheet.userID = apiTimesheet.workerID
            timesheet.jobID = apiTimesheet.jobID
            timesheet.jobName = apiTimesheet.jobName
            timesheet.clockIn = formatter.date(from: apiTimesheet.clockIn) ?? Date()
            timesheet.clockOut = apiTimesheet.clockOut.flatMap { formatter.date(from: $0) }
            timesheet.hours = apiTimesheet.hours
            timesheet.status = apiTimesheet.status
            timesheet.notes = apiTimesheet.notes
            timesheet.createdAt = formatter.date(from: apiTimesheet.createdAt) ?? Date()
            return timesheet
        }
    }
    
    func createTimesheet(_ timesheet: Timesheet) async throws {
        // Use clockIn endpoint
        _ = try await clockIn(jobID: timesheet.jobID ?? "", latitude: nil, longitude: nil, location: nil)
    }
    
    func updateTimesheet(_ timesheet: Timesheet) async throws {
        // For status changes like approve/reject, would need backend endpoint
        // For now, this is a stub
    }
    
    func deleteTimesheet(id: String) async throws {
        // Would need backend endpoint - stub for now
    }
    
    // MARK: - Workers
    
    func fetchWorkers() async throws -> [User] {
        let apiWorkers = try await getWorkers()
        return apiWorkers.map { apiUser in
            User(
                id: apiUser.id,
                name: apiUser.name,
                email: apiUser.email,
                phone: apiUser.phone,
                role: UserRole(rawValue: apiUser.role) ?? .worker,
                hourlyRate: apiUser.hourlyRate,
                active: apiUser.active,
                createdAt: ISO8601DateFormatter().date(from: apiUser.createdAt) ?? Date()
            )
        }
    }
    
    func inviteWorker(email: String, name: String) async throws -> User {
        let createdWorker = try await createWorker([
            "email": email,
            "name": name,
            "role": "worker"
        ])
        
        // Convert API response to User model
        let user = User(
            id: createdWorker.id,
            name: createdWorker.name,
            email: createdWorker.email,
            role: UserRole(rawValue: createdWorker.role) ?? .worker,
            hourlyRate: createdWorker.hourlyRate,
            active: createdWorker.active
        )
        return user
    }
    
    func updateWorker(_ worker: User) async throws {
        guard let id = worker.id else { return }
        var body: [String: Any] = [
            "name": worker.name,
            "active": worker.active
        ]
        if let phone = worker.phone { body["phone"] = phone }
        if let hourlyRate = worker.hourlyRate { body["hourlyRate"] = hourlyRate }
        
        _ = try await updateWorker(id: id, updates: body)
    }
    
    func assignWorkerToJob(workerID: String, jobID: String) async throws {
        // Use dedicated backend endpoint for worker assignment
        struct AssignResponse: Codable {
            let message: String
        }
        let _: AssignResponse = try await request("POST", path: "/jobs/\(jobID)/assign-worker", body: [
            "workerID": workerID
        ])
    }
    
    func unassignWorkerFromJob(workerID: String, jobID: String) async throws {
        // Use dedicated backend endpoint for worker unassignment
        struct UnassignResponse: Codable {
            let message: String
        }
        let _: UnassignResponse = try await request("DELETE", path: "/jobs/\(jobID)/unassign-worker/\(workerID)")
    }
    
    
    func updateUser(_ user: User) async throws {
        _ = try await updateProfile(name: user.name, phone: user.phone, photoURL: user.photoURL)
    }
    
    func fetchUser(userID: String) async throws -> User? {
        struct UserResponse: Codable {
            let user: APIUser
        }
        do {
            let response: UserResponse = try await request("GET", path: "/users/\(userID)")
            return User(
                id: response.user.id,
                name: response.user.name,
                email: response.user.email,
                role: UserRole(rawValue: response.user.role) ?? .worker,
                hourlyRate: response.user.hourlyRate,
                active: response.user.active,
                createdAt: ISO8601DateFormatter().date(from: response.user.createdAt) ?? Date()
            )
        } catch {
            return nil
        }
    }
    
    // MARK: - Upload
    
    func uploadImage(_ image: UIImage, type: String, id: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.uploadFailed
        }
        
        let filename = "\(id)_\(Date().timeIntervalSince1970).jpg"
        
        let response: UploadResponse
        switch type {
        case "receipt":
            response = try await uploadReceipt(imageData: imageData, filename: filename)
        case "profile", "company":
            response = try await uploadProfilePhoto(imageData: imageData, filename: filename)
        default:
            response = try await uploadDocument(fileData: imageData, filename: filename)
        }
        
        return response.url
    }
    
    // MARK: - AI Chat
    
    func sendChatMessage(_ message: String) async throws -> String {
        struct ChatResponse: Codable {
            let response: String
        }
        let response: ChatResponse = try await request("POST", path: "/ai/chat", body: ["message": message])
        return response.response
    }
    
    // MARK: - Settings
    
    func getWorkerPermissions() async throws -> WorkerPermissions {
        return try await request("GET", path: "/settings/permissions")
    }
    
    func saveWorkerPermissions(_ permissions: WorkerPermissions) async throws {
        let body: [String: Any] = [
            "canViewFinancials": permissions.canViewFinancials,
            "canUploadReceipts": permissions.canUploadReceipts,
            "canApproveTimesheets": permissions.canApproveTimesheets,
            "canSeeAIInsights": permissions.canSeeAIInsights,
            "canViewAllJobs": permissions.canViewAllJobs
        ]
        let _: MessageResponse = try await request("PUT", path: "/settings/permissions", body: body)
    }
    
    struct AISettings: Codable {
        var aiMode: String
        var autoFillReceipts: Bool
        var autoAssignReceipts: Bool
        var autoCalculateLabor: Bool
        var autoGenerateSummaries: Bool
        var autoGenerateInsights: Bool
        var minConfidence: Double
        var flagLowConfidence: Bool
        var flagUnusualHours: Bool
        var maxDailyHours: Double
        var budgetAlertThreshold: Double
        
        static var `default`: AISettings {
            AISettings(
                aiMode: "assist",
                autoFillReceipts: true,
                autoAssignReceipts: true,
                autoCalculateLabor: true,
                autoGenerateSummaries: false,
                autoGenerateInsights: true,
                minConfidence: 85,
                flagLowConfidence: true,
                flagUnusualHours: true,
                maxDailyHours: 12,
                budgetAlertThreshold: 75
            )
        }
    }
    
    func getAISettings() async throws -> AISettings {
        return try await request("GET", path: "/settings/ai")
    }
    
    func saveAISettings(_ settings: AISettings) async throws {
        let body: [String: Any] = [
            "aiMode": settings.aiMode,
            "autoFillReceipts": settings.autoFillReceipts,
            "autoAssignReceipts": settings.autoAssignReceipts,
            "autoCalculateLabor": settings.autoCalculateLabor,
            "autoGenerateSummaries": settings.autoGenerateSummaries,
            "autoGenerateInsights": settings.autoGenerateInsights,
            "minConfidence": settings.minConfidence,
            "flagLowConfidence": settings.flagLowConfidence,
            "flagUnusualHours": settings.flagUnusualHours,
            "maxDailyHours": settings.maxDailyHours,
            "budgetAlertThreshold": settings.budgetAlertThreshold
        ]
        let _: MessageResponse = try await request("PUT", path: "/settings/ai", body: body)
    }
    
    // MARK: - Worker Payments
    
    func createPayment(_ payment: WorkerPayment) async throws -> WorkerPayment {
        let body: [String: Any] = [
            "workerID": payment.workerID,
            "amount": payment.amount,
            "paymentDate": ISO8601DateFormatter().string(from: payment.paymentDate),
            "periodStart": ISO8601DateFormatter().string(from: payment.periodStart),
            "periodEnd": ISO8601DateFormatter().string(from: payment.periodEnd),
            "hoursWorked": payment.hoursWorked,
            "hourlyRate": payment.hourlyRate,
            "calculatedEarnings": payment.calculatedEarnings,
            "paymentMethod": payment.paymentMethod.rawValue,
            "notes": payment.notes as Any,
            "referenceNumber": payment.referenceNumber as Any
        ]
        return try await request("POST", path: "/payments", body: body)
    }
    
    func getPayments(ownerID: String) async throws -> [WorkerPayment] {
        return try await request("GET", path: "/payments")
    }
    
    func getPaymentsForWorker(workerID: String) async throws -> [WorkerPayment] {
        return try await request("GET", path: "/payments/worker/\(workerID)")
    }
}
