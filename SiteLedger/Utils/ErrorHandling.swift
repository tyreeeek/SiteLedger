import Foundation

/// User-friendly error messages for common failures
enum UserFacingError: LocalizedError {
    // Network Errors
    case networkUnavailable
    case requestTimeout
    case serverError
    
    // Authentication Errors
    case invalidCredentials
    case accountNotFound
    case emailAlreadyInUse
    case weakPassword
    case authenticationRequired
    
    // Database Errors
    case dataNotFound
    case permissionDenied
    case quotaExceeded
    
    // Storage Errors
    case uploadFailed
    case fileTooLarge
    case invalidFileType
    
    // Validation Errors
    case invalidInput(field: String)
    case missingRequiredField(field: String)
    case invalidEmail
    case invalidPhoneNumber
    
    // Location Errors
    case locationPermissionDenied
    case locationUnavailable
    case locationAccuracyLow
    
    // AI/OCR Errors
    case ocrFailed
    case aiProcessingFailed
    case rateLimitExceeded
    
    // Generic
    case unknown(message: String)
    
    var errorDescription: String? {
        switch self {
        // Network
        case .networkUnavailable:
            return "No internet connection. Please check your network and try again."
        case .requestTimeout:
            return "The request timed out. Please try again."
        case .serverError:
            return "Server error. Please try again in a few moments."
            
        // Authentication
        case .invalidCredentials:
            return "Invalid email or password. Please check your credentials and try again."
        case .accountNotFound:
            return "No account found with this email. Please sign up first."
        case .emailAlreadyInUse:
            return "This email is already registered. Please use a different email or sign in."
        case .weakPassword:
            return "Password must be at least 6 characters long."
        case .authenticationRequired:
            return "Please sign in to continue."
            
        // Database
        case .dataNotFound:
            return "Data not found. It may have been deleted."
        case .permissionDenied:
            return "You don't have permission to perform this action."
        case .quotaExceeded:
            return "Storage quota exceeded. Please contact support."
            
        // Storage
        case .uploadFailed:
            return "File upload failed. Please try again."
        case .fileTooLarge:
            return "File is too large. Please choose a smaller file (max 10MB)."
        case .invalidFileType:
            return "Invalid file type. Please upload an image or PDF."
            
        // Validation
        case .invalidInput(let field):
            return "\(field) is invalid. Please check and try again."
        case .missingRequiredField(let field):
            return "\(field) is required. Please fill it in."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .invalidPhoneNumber:
            return "Please enter a valid phone number."
            
        // Location
        case .locationPermissionDenied:
            return "Location permission denied. Enable it in Settings to use this feature."
        case .locationUnavailable:
            return "Unable to get your location. Please try again or check your device settings."
        case .locationAccuracyLow:
            return "Location accuracy is too low. Please move to an area with better GPS signal."
            
        // AI/OCR
        case .ocrFailed:
            return "Could not read receipt. Please enter information manually."
        case .aiProcessingFailed:
            return "AI processing failed. Data may need manual review."
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment and try again."
            
        // Generic
        case .unknown(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your Wi-Fi or cellular connection"
        case .requestTimeout:
            return "Ensure you have a stable internet connection"
        case .invalidCredentials:
            return "Tap 'Forgot Password?' to reset your password"
        case .accountNotFound:
            return "Tap 'Create Account' to sign up"
        case .locationPermissionDenied:
            return "Open Settings → SiteLedger → Location to enable"
        case .uploadFailed:
            return "Check your internet connection and try again"
        case .ocrFailed:
            return "You can enter receipt details manually"
        default:
            return nil
        }
    }
}

/// Convert common errors to user-friendly errors
extension Error {
    func toUserFacingError() -> UserFacingError {
        let errorString = self.localizedDescription.lowercased()
        
        // Network errors
        if errorString.contains("network") || errorString.contains("internet") || errorString.contains("connection") {
            return .networkUnavailable
        }
        if errorString.contains("timeout") || errorString.contains("timed out") {
            return .requestTimeout
        }
        if errorString.contains("server") || errorString.contains("500") || errorString.contains("503") {
            return .serverError
        }
        
        // Auth errors
        if errorString.contains("wrong-password") || errorString.contains("invalid-credential") {
            return .invalidCredentials
        }
        if errorString.contains("user-not-found") {
            return .accountNotFound
        }
        if errorString.contains("email-already-in-use") {
            return .emailAlreadyInUse
        }
        if errorString.contains("weak-password") {
            return .weakPassword
        }
        if errorString.contains("requires-recent-login") || errorString.contains("unauthenticated") {
            return .authenticationRequired
        }
        
        // Database errors
        if errorString.contains("permission-denied") || errorString.contains("insufficient permissions") {
            return .permissionDenied
        }
        if errorString.contains("not found") || errorString.contains("does not exist") {
            return .dataNotFound
        }
        if errorString.contains("quota") || errorString.contains("resource-exhausted") {
            return .quotaExceeded
        }
        
        // Storage errors
        if errorString.contains("upload") {
            return .uploadFailed
        }
        if errorString.contains("file too large") || errorString.contains("size limit") {
            return .fileTooLarge
        }
        
        // Location errors
        if errorString.contains("location") && errorString.contains("denied") {
            return .locationPermissionDenied
        }
        if errorString.contains("location") && (errorString.contains("unavailable") || errorString.contains("failed")) {
            return .locationUnavailable
        }
        
        // AI/OCR errors
        if errorString.contains("ocr") {
            return .ocrFailed
        }
        if errorString.contains("rate limit") || errorString.contains("too many requests") {
            return .rateLimitExceeded
        }
        
        // Default
        return .unknown(message: self.localizedDescription)
    }
}

/// Retry configuration for network operations
struct RetryConfig: Sendable {
    let maxAttempts: Int
    let initialDelay: TimeInterval
    let maxDelay: TimeInterval
    let multiplier: Double
    
    nonisolated static let `default` = RetryConfig(
        maxAttempts: 3,
        initialDelay: 1.0,
        maxDelay: 10.0,
        multiplier: 2.0
    )
    
    nonisolated static let aggressive = RetryConfig(
        maxAttempts: 5,
        initialDelay: 0.5,
        maxDelay: 5.0,
        multiplier: 1.5
    )
}

/// Retry a network operation with exponential backoff
func retryOperation<T>(
    config: RetryConfig = .default,
    operation: @escaping () async throws -> T
) async throws -> T {
    var attempt = 0
    var delay = config.initialDelay
    
    while attempt < config.maxAttempts {
        do {
            return try await operation()
        } catch {
            attempt += 1
            
            // Don't retry on certain errors
            let userError = error.toUserFacingError()
            switch userError {
            case .permissionDenied, .authenticationRequired, .invalidCredentials, .accountNotFound:
                // These won't fix themselves with retry
                throw error
            default:
                break
            }
            
            // If this was the last attempt, throw the error
            if attempt >= config.maxAttempts {
                throw error
            }
            
            // Wait before retrying
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Increase delay for next retry (exponential backoff)
            delay = min(delay * config.multiplier, config.maxDelay)
            
        }
    }
    
    fatalError("Should not reach here")
}
