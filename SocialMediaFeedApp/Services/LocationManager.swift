//
//  LocationManager.swift
//  SocialMediaFeedApp
//
//  Created by Prince Lunagariya on 21/04/26.
//

import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject {

    @Published var locationString: String = ""
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isFetchingLocation: Bool = false
    @Published var errorMessage: String?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startFetchingLocation()
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enter location manually."
        @unknown default:
            errorMessage = "Location unavailable."
        }
    }

    private func startFetchingLocation() {
        isFetchingLocation = true
        errorMessage = nil
        manager.requestLocation()
    }

    private func handleLocationUpdate(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isFetchingLocation = false
                if let error = error {
                    self.errorMessage = "Could not determine location: \(error.localizedDescription)"
                    return
                }
                if let placemark = placemarks?.first {
                    var components: [String] = []
                    if let locality = placemark.locality { components.append(locality) }
                    if let area = placemark.administrativeArea { components.append(area) }
                    if let country = placemark.country { components.append(country) }
                    self.locationString = components.joined(separator: ", ")
                }
            }
        }
    }

    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startFetchingLocation()
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enter location manually."
        default:
            break
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            Task { @MainActor in self.isFetchingLocation = false }
            return
        }
        Task { @MainActor in self.handleLocationUpdate(location) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isFetchingLocation = false
            self.errorMessage = "Failed to get location. Please enter manually."
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in self.handleAuthorizationChange(status) }
    }
}
