import Foundation
import Combine
import AuthenticationServices

/// AuthService that uses the DigitalOcean PostgreSQL backend instead of Firebase
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let apiService = APIService.shared
    
    init() {
        // Load stored token and check if user is still authenticated
        Task {
            await loadStoredSession()
        }
    }
    
    // MARK: - Session Management
    
    private func loadStoredSession() async {
        await apiService.loadStoredToken()
        
        // Try to get current user with stored token
        do {
            let apiUser = try await apiService.getCurrentUser()
            let user = mapAPIUserToUser(apiUser)
            
            // Configure API keys after session restore
            await APIKeyManager.shared.configure()
            
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            // Token invalid or expired, clear it
            await apiService.clearToken()
            APIKeyManager.shared.clearCache()
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        }
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String, name: String, role: UserRole = .owner) async throws {
        await MainActor.run { 
            self.isLoading = true 
            self.errorMessage = nil
        }
        
        defer {
            Task { @MainActor in self.isLoading = false }
        }
        
        do {
            let response = try await apiService.signup(
                email: email,
                password: password,
                name: name,
                role: role.rawValue
            )
            
            let user = mapAPIUserToUser(response.user)
            
            // Configure API keys after successful signup
            await APIKeyManager.shared.configure()
            
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.errorMessage = nil
            }
            
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        await MainActor.run { 
            self.isLoading = true 
            self.errorMessage = nil
        }
        
        defer {
            Task { @MainActor in self.isLoading = false }
        }
        
        do {
            let response = try await apiService.login(email: email, password: password)
            let user = mapAPIUserToUser(response.user)
            
            // Configure API keys after successful login
            await APIKeyManager.shared.configure()
            
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.errorMessage = nil
            }
            
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        Task {
            await apiService.clearToken()
        }
        
        // Clear cached API keys
        APIKeyManager.shared.clearCache()
        
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
        
        // Post notification to clear all caches in ViewModels
        NotificationCenter.default.post(name: .userDidSignOut, object: nil)
        
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws -> APIService.MessageResponse {
        await MainActor.run { 
            self.isLoading = true 
            self.errorMessage = nil
        }
        
        defer {
            Task { @MainActor in self.isLoading = false }
        }
        
        do {
            let response = try await apiService.forgotPassword(email: email)
            return response
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func confirmResetPassword(token: String, newPassword: String) async throws {
        await MainActor.run { 
            self.isLoading = true 
            self.errorMessage = nil
        }
        
        defer {
            Task { @MainActor in self.isLoading = false }
        }
        
        do {
            _ = try await apiService.confirmResetPassword(token: token, newPassword: newPassword)
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Change Password
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        defer {
            Task { @MainActor in self.isLoading = false }
        }
        
        do {
            try await apiService.changePassword(currentPassword: currentPassword, newPassword: newPassword)
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Change Email
    
    func changeEmail(newEmail: String, password: String) async throws {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        defer {
            Task { @MainActor in self.isLoading = false }
        }
        
        do {
            let response = try await apiService.changeEmail(newEmail: newEmail, password: password)
            // Update current user's email
            if var user = currentUser {
                user.email = response.newEmail
                await MainActor.run {
                    self.currentUser = user
                }
            }
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    @MainActor
    func signInWithApple(_ result: Result<ASAuthorization, Error>) async throws {
        self.isLoading = true 
        self.errorMessage = nil
        
        defer {
            self.isLoading = false
        }
        
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw APIError.serverError("Invalid Apple credential")
            }
            
            guard let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                throw APIError.serverError("Could not get identity token")
            }
            
            guard let authorizationCodeData = appleIDCredential.authorizationCode,
                  let authorizationCode = String(data: authorizationCodeData, encoding: .utf8) else {
                throw APIError.serverError("Could not get authorization code")
            }
            
            let appleUserID = appleIDCredential.user
            
            // Get user's name (only available on first sign-in)
            var fullName: String? = nil
            if let nameComponents = appleIDCredential.fullName {
                let firstName = nameComponents.givenName ?? ""
                let lastName = nameComponents.familyName ?? ""
                fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                if fullName?.isEmpty == true { fullName = nil }
            }
            
            // Email may be nil on subsequent sign-ins
            let email = appleIDCredential.email
            
            #if DEBUG
            print("🍎 [Apple Sign-In] Credentials extracted, calling API...")
            #endif
            
            do {
                let response = try await apiService.loginWithApple(
                    identityToken: identityToken,
                    authorizationCode: authorizationCode,
                    fullName: fullName,
                    email: email,
                    appleUserID: appleUserID
                )
                
                #if DEBUG
                print("🍎 [Apple Sign-In] API call successful, mapping user...")
                #endif
                
                let user = mapAPIUserToUser(response.user)
                
                #if DEBUG
                print("🍎 [Apple Sign-In] User mapped: \(user.email), role: \(user.role.rawValue)")
                #endif
                
                // Configure API keys after successful login
                await APIKeyManager.shared.configure()
                
                #if DEBUG
                print("🍎 [Apple Sign-In] Setting isAuthenticated = true")
                #endif
                
                self.currentUser = user
                self.isAuthenticated = true
                self.errorMessage = nil
                
                #if DEBUG
                print("🍎 [Apple Sign-In] ✅ SUCCESS - isAuthenticated: \(self.isAuthenticated), user: \(self.currentUser?.email ?? "nil")")
                #endif
                
            } catch let error as APIError {
                #if DEBUG
                print("🍎 [Apple Sign-In] ❌ API Error: \(error.localizedDescription)")
                #endif
                self.errorMessage = error.localizedDescription
                throw error
            }
            
        case .failure(let error):
            let errorCode = (error as NSError).code
            let errorDomain = (error as NSError).domain
            #if DEBUG
            print("🔴 Apple Sign-In Failed - Code: \(errorCode), Domain: \(errorDomain)")
            print("🔴 Description: \(error.localizedDescription)")
            #endif
            
            // Handle Apple Sign-In specific errors
            if errorDomain == "com.apple.AuthenticationServices.AuthorizationError" {
                switch errorCode {
                case 1000:
                    // System error during auth - usually network or framework issue
                    let systemError = APIError.serverError("Sign-in failed. Please try again.")
                    await MainActor.run {
                        self.errorMessage = systemError.localizedDescription
                    }
                    throw systemError
                    
                case 1001:
                    // User canceled
                    let cancelError = APIError.serverError("Sign-in canceled.")
                    await MainActor.run {
                        self.errorMessage = cancelError.localizedDescription
                    }
                    throw cancelError
                    
                default:
                    #if DEBUG
                    print("🔴 Unknown Apple Auth error code: \(errorCode)")
                    #endif
                    let unknownError = APIError.serverError("Sign-in failed (code \(errorCode))")
                    await MainActor.run {
                        self.errorMessage = unknownError.localizedDescription
                    }
                    throw unknownError
                }
            }
            
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    
    func createWorker(email: String, password: String, name: String, ownerID: String, hourlyRate: Double? = nil) async throws {
        guard currentUser != nil else {
            throw APIError.unauthorized
        }
        
        await MainActor.run { self.isLoading = true }
        
        defer {
            Task { @MainActor in self.isLoading = false }
        }
        
        do {
            var params: [String: Any] = [
                "email": email,
                "password": password,
                "name": name,
                "ownerID": ownerID
            ]
            if let hourlyRate = hourlyRate {
                params["hourlyRate"] = hourlyRate
            }
            _ = try await apiService.createWorker(params)
            
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Session Validation
    
    func validateSession() async {
        do {
            let apiUser = try await apiService.getCurrentUser()
            let user = mapAPIUserToUser(apiUser)
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        }
    }
    
    func checkAuthStatus() {
        Task {
            await validateSession()
        }
    }
    
    // MARK: - Account Management
    
    /// Delete user account completely (including Apple Sign-In credentials)
    /// This will permanently delete all user data from the backend and revoke all authentication
    func deleteAccount() async throws {
        await MainActor.run {
            self.isLoading = true
        }
        
        defer {
            Task { @MainActor in self.isLoading = false }
        }
        
        do {
            // 1. Delete account from backend (deletes all user data)
            try await apiService.deleteAccount()
            
            // 2. If user signed in with Apple, revoke Apple credentials
            // Note: Apple doesn't provide a public API to revoke credentials from client side
            // The backend should handle token invalidation on their side
            // We just clear local credentials here
            
            // 3. Clear all local authentication data
            await apiService.clearToken()
            APIKeyManager.shared.clearCache()
            
            // 4. Clear keychain if storing any Apple credentials
            // (Currently we use UserDefaults for JWT, but adding this for completeness)
            UserDefaults.standard.removeObject(forKey: "api_access_token")
            UserDefaults.standard.removeObject(forKey: "api_refresh_token")
            UserDefaults.standard.removeObject(forKey: "apple_user_id")
            
            // 5. Update UI state
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
                self.errorMessage = nil
            }
            
            // 6. Notify all views to clear data
            NotificationCenter.default.post(name: .userDidSignOut, object: nil)
            
            #if DEBUG
            print("[AuthService] ✅ Account deleted successfully - all data cleared")
            #endif
            
        } catch let error as APIError {
            #if DEBUG
            print("[AuthService] ❌ Account deletion failed: \(error.localizedDescription)")
            #endif
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        } catch {
            #if DEBUG
            print("[AuthService] ❌ Account deletion failed: \(error.localizedDescription)")
            #endif
            throw error
        }
    }
    
    func resetAllData() async throws {
        await MainActor.run {
            self.isLoading = true
        }
        
        defer {
            Task { @MainActor in self.isLoading = false }
        }
        
        do {
            try await apiService.resetAllData()
            
            // Post notification to clear all caches in ViewModels
            NotificationCenter.default.post(name: .userDidSignOut, object: nil)
            
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    private func mapAPIUserToUser(_ apiUser: APIService.APIUser) -> User {
        let role: UserRole = apiUser.role == "worker" ? .worker : .owner
        
        // Parse date from ISO8601 string
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.date(from: apiUser.createdAt) ?? Date()
        
        return User(
            id: apiUser.id,
            ownerID: apiUser.ownerId,
            name: apiUser.name,
            email: apiUser.email,
            phone: apiUser.phone,
            photoURL: apiUser.photoURL,
            role: role,
            hourlyRate: apiUser.hourlyRate,
            active: apiUser.active,
            assignedJobIDs: apiUser.assignedJobIDs,
            createdAt: createdAt
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userDidSignOut = Notification.Name("userDidSignOut")
}
