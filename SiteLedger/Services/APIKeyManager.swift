import Foundation

/// API Key Manager - Fetches keys securely from backend
class APIKeyManager {
    static let shared = APIKeyManager()
    
    private var isConfigured = false
    private var cachedOCRKey: String?
    private var cachedOpenRouterKey: String?
    private var cachedAIModel: String?
    
    private init() {}
    
    /// Configure by fetching keys from backend (requires authenticated user)
    func configure() async {
        await fetchKeysFromBackend()
        isConfigured = true
    }
    
    private func fetchKeysFromBackend() async {
        // Only fetch if user is authenticated
        guard let token = UserDefaults.standard.string(forKey: "api_access_token") else {
            #if DEBUG
            print("[APIKeyManager] No auth token found, skipping key fetch")
            #endif
            return
        }
        
        // Use the same base URL as APIService - Production DigitalOcean server with HTTPS
        let baseURL = "https://api.siteledger.ai/api"
        
        guard let url = URL(string: "\(baseURL)/config/keys") else { 
            #if DEBUG
            print("[APIKeyManager] Invalid URL")
            #endif
            return 
        }
        
        #if DEBUG
        print("[APIKeyManager] Fetching keys from: \(url)")
        #endif
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                #if DEBUG
                print("[APIKeyManager] Invalid response type")
                #endif
                return
            }
            
            #if DEBUG
            print("[APIKeyManager] Response status: \(httpResponse.statusCode)")
            #endif
            
            guard httpResponse.statusCode == 200 else {
                #if DEBUG
                print("[APIKeyManager] Failed with status: \(httpResponse.statusCode)")
                #endif
                return
            }
            
            struct KeysResponse: Codable {
                let ocrSpaceKey: String
                let openRouterKey: String
                let aiModel: String
            }
            
            let keys = try JSONDecoder().decode(KeysResponse.self, from: data)
            cachedOCRKey = keys.ocrSpaceKey
            cachedOpenRouterKey = keys.openRouterKey
            cachedAIModel = keys.aiModel
            
            #if DEBUG
            print("[APIKeyManager] ✅ Keys configured - OCR: \(keys.ocrSpaceKey.prefix(10))..., AI: \(keys.openRouterKey.prefix(10))...")
            #endif
        } catch {
            #if DEBUG
            print("[APIKeyManager] Error fetching keys: \(error)")
            #endif
        }
    }
    
    // MARK: - AI API Keys (fetched from backend, with fallbacks)
    
    var openRouterAPIKey: String {
        cachedOpenRouterKey ?? ""
    }
    
    var ocrSpaceAPIKey: String {
        cachedOCRKey ?? ""
    }
    
    var openRouterEndpoint: String {
        return "https://openrouter.ai/api/v1/chat/completions"
    }
    
    var ocrSpaceEndpoint: String {
        return "https://api.ocr.space/parse/image"
    }
    
    var aiModelName: String {
        cachedAIModel ?? "meta-llama/llama-3.3-70b-instruct:free"
    }
    
    var isFullyConfigured: Bool {
        return isConfigured && cachedOCRKey != nil
    }
    
    func refresh() async {
        await fetchKeysFromBackend()
        isConfigured = true
    }
    
    func clearCache() {
        cachedOCRKey = nil
        cachedOpenRouterKey = nil
        cachedAIModel = nil
        isConfigured = false
    }
}
