import Foundation
import CoreLocation
import Combine

/// Singleton location manager for GPS tracking
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    
    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 // Update every 10 meters
    }
    
    // MARK: - Public Methods
    
    /// Request location permissions
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    /// Get current location as a formatted string
    func getCurrentLocationString() async -> String? {
        guard let location = await getCurrentLocation() else {
            return nil
        }
        
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        // Try to get address from coordinates
        if let address = await getAddressFromCoordinates(location: location) {
            return address
        }
        
        // Fallback to coordinates
        return String(format: "%.6f, %.6f", latitude, longitude)
    }
    
    /// Get current CLLocation
    func getCurrentLocation() async -> CLLocation? {
        // Check authorization
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            manager.requestLocation()
        }
    }
    
    /// Start continuous location updates
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    /// Stop location updates
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
    
    // MARK: - Reverse Geocoding
    
    /// Convert coordinates to human-readable address
    private func getAddressFromCoordinates(location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }
            
            var addressComponents: [String] = []
            
            if let streetNumber = placemark.subThoroughfare {
                addressComponents.append(streetNumber)
            }
            if let street = placemark.thoroughfare {
                addressComponents.append(street)
            }
            if let city = placemark.locality {
                addressComponents.append(city)
            }
            if let state = placemark.administrativeArea {
                addressComponents.append(state)
            }
            
            return addressComponents.isEmpty ? nil : addressComponents.joined(separator: ", ")
        } catch {
            return nil
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            break
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.locationError = "Location permission denied. Enable in Settings."
            }
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
        }
        
        // Resume continuation if waiting
        if let continuation = locationContinuation {
            continuation.resume(returning: location)
            locationContinuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        DispatchQueue.main.async {
            self.locationError = error.localizedDescription
        }
        
        // Resume continuation with nil if waiting
        if let continuation = locationContinuation {
            continuation.resume(returning: nil)
            locationContinuation = nil
        }
    }
    
    // MARK: - Distance Calculation
    
    /// Calculate distance between two location strings (coordinates)
    func calculateDistance(from location1: String?, to location2: String?) -> CLLocationDistance? {
        guard let loc1 = location1, let loc2 = location2 else { return nil }
        
        // Parse coordinates from strings
        let components1 = loc1.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        let components2 = loc2.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        
        guard components1.count == 2, components2.count == 2 else { return nil }
        
        let coord1 = CLLocation(latitude: components1[0], longitude: components1[1])
        let coord2 = CLLocation(latitude: components2[0], longitude: components2[1])
        
        return coord1.distance(from: coord2)
    }
}
