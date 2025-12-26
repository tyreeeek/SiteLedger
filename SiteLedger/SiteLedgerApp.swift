import SwiftUI

@main
struct SiteLedgerApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    init() {
        // Using DigitalOcean backend - no Firebase configuration needed
        
        // Configure API keys on app launch
        Task {
            await APIKeyManager.shared.configure()
            #if DEBUG
            print("[App] API keys configured")
            #endif
        }
        
        // Network monitoring starts automatically in NetworkMonitor.init()
        #if DEBUG
        print("[App] Network monitoring initialized")
        #endif
        
        // Start periodic health checks (every 30 seconds)
        Task.detached {
            await Self.startHealthChecks()
        }
    }
    
    /// Periodic health check to maintain backend connection
    private static func startHealthChecks() async {
        while true {
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            
            let isHealthy = await APIService.shared.checkHealth()
            if !isHealthy {
                #if DEBUG
                print("[App] ⚠️ Backend health check failed")
                #endif
            }
        }
    }
    
    /// Converts the appTheme string to a ColorScheme for the app
    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil  // "system" follows device setting
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                // Check authentication first - authenticated users always go to main view
                if authService.isAuthenticated, let user = authService.currentUser {
                    // Route based on user role
                    switch user.role {
                    case .owner:
                        OwnerMainView()
                            .environmentObject(authService)
                    case .worker:
                        WorkerMainView()
                            .environmentObject(authService)
                    }
                } else if !hasCompletedOnboarding {
                    // Show onboarding for first-time users
                    OnboardingView()
                } else {
                    WelcomeView()
                        .environmentObject(authService)
                }
            }
            .preferredColorScheme(colorScheme)
        }
    }
}
