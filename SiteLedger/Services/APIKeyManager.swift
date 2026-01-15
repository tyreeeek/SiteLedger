import Foundation

/// API Key Manager - Configuration from backend
/// Note: No API keys needed - using Puter.js (free AI) and Tesseract (local OCR)
class APIKeyManager {
    static let shared = APIKeyManager()
    
    private var isConfigured = false
    
    private init() {}
    
    /// Configure by fetching config from backend (requires authenticated user)
    func configure() async {
        await fetchConfigFromBackend()
        isConfigured = true
    }
    
    private func fetchConfigFromBackend() async {
        // Only fetch if user is authenticated
        guard let token = UserDefaults.standard.string(forKey: "api_access_token") else {
            #if DEBUG
            print("[APIKeyManager] No auth token found, skipping config fetch")
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
        print("[APIKeyManager] Fetching config from: \(url)")
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
            
            struct ConfigResponse: Codable {
                let aiProvider: String
                let ocrProvider: String
                let requiresApiKeys: Bool
            }
            
            let config = try JSONDecoder().decode(ConfigResponse.self, from: data)
            
            #if DEBUG
            print("[APIKeyManager] ✅ Config loaded - AI: \(config.aiProvider), OCR: \(config.ocrProvider), No API keys needed: \(!config.requiresApiKeys)")
            #endif
        } catch {
            #if DEBUG
            print("[APIKeyManager] Error fetching config: \(error)")
            #endif
        }
    }
    
    // MARK: - Configuration (no API keys needed)
    
    var isFullyConfigured: Bool {
        return isConfigured
    }
    
    func refresh() async {
        await fetchConfigFromBackend()
        isConfigured = true
    }
    
    func clearCache() {
        isConfigured = false
    }
}
