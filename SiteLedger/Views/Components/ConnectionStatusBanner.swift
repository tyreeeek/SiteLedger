import SwiftUI

/// Connection status banner shown at top of screen when network issues occur
struct ConnectionStatusBanner: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    @State private var showBanner = false
    @State private var lastConnectionState = true
    
    var body: some View {
        VStack(spacing: 0) {
            if showBanner && !networkMonitor.isConnected {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("No internet connection")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    // Reconnecting indicator
                    ProgressView()
                        .scaleEffect(0.8)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.orange)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showBanner)
        .onChange(of: networkMonitor.isConnected) { oldValue, newValue in
            handleConnectionChange(connected: newValue)
        }
        .onAppear {
            lastConnectionState = networkMonitor.isConnected
            showBanner = !networkMonitor.isConnected
        }
    }
    
    private func handleConnectionChange(connected: Bool) {
        if connected != lastConnectionState {
            if !connected {
                // Lost connection - show banner immediately
                showBanner = true
                HapticsManager.shared.warning()
            } else {
                // Regained connection - hide banner after brief delay
                HapticsManager.shared.success()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showBanner = false
                }
            }
            
            lastConnectionState = connected
        }
    }
}

/// View modifier to add connection status banner to any view
struct WithConnectionStatus: ViewModifier {
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            ConnectionStatusBanner()
            content
        }
    }
}

extension View {
    func withConnectionStatus() -> some View {
        modifier(WithConnectionStatus())
    }
}

#Preview {
    ConnectionStatusBanner()
}
