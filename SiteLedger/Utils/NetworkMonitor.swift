import Foundation
import Network
import Combine

/// Network connectivity monitor using NWPathMonitor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected: Bool = true
    @Published var connectionType: NWInterface.InterfaceType?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isConnected = path.status == .satisfied
                self.connectionType = path.availableInterfaces.first?.type
                
                if path.status == .satisfied {
                    print("[NetworkMonitor] ✅ Network connected via \(path.availableInterfaces.first?.type.description ?? "unknown")")
                } else {
                    print("[NetworkMonitor] ❌ Network disconnected")
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    nonisolated func stopMonitoring() {
        monitor.cancel()
    }
    
    deinit {
        monitor.cancel()
    }
}

extension NWInterface.InterfaceType {
    var description: String {
        switch self {
        case .wifi: return "WiFi"
        case .cellular: return "Cellular"
        case .wiredEthernet: return "Ethernet"
        case .loopback: return "Loopback"
        case .other: return "Other"
        @unknown default: return "Unknown"
        }
    }
}
