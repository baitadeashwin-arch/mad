//
//  LocationService.swift
//  AntiSocial
//
//  Requests permission only when Nearby Mode needs it. Exact GPS stays in memory.
//

import Foundation
import CoreLocation
import Combine

enum LocationPermissionState {
    case notDetermined, authorized, denied, restricted
}

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    @Published private(set) var permissionState: LocationPermissionState = .notDetermined
    @Published private(set) var lastExactCoordinate: CLLocationCoordinate2D?
    @Published private(set) var lastError: String?

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 250
        refreshPermission()
    }

    var coarseCoordinate: CLLocationCoordinate2D? {
        guard let lastExactCoordinate else { return nil }
        return LocationPrivacy.coarsen(coordinate: lastExactCoordinate)
    }

    func requestWhenInUse() {
        refreshPermission()
        if permissionState == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func requestOneShotLocation() async throws -> CLLocationCoordinate2D {
        requestWhenInUse()
        refreshPermission()
        if permissionState == .denied || permissionState == .restricted {
            throw AuthErrorModel(message: "location denied")
        }
        if let lastExactCoordinate {
            return lastExactCoordinate
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.manager.requestLocation()
        }
    }

    func stopUpdates() {
        manager.stopUpdatingLocation()
    }

    private func refreshPermission() {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            permissionState = .authorized
        case .denied:
            permissionState = .denied
        case .restricted:
            permissionState = .restricted
        default:
            permissionState = .notDetermined
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.refreshPermission()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastExactCoordinate = location.coordinate
        lastError = nil
        continuation?.resume(returning: location.coordinate)
        continuation = nil
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastError = UserFacingError.message(from: error)
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
