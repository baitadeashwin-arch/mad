import Foundation
import CoreLocation
import MapKit
import SwiftUI

struct NearbyMapPin: Identifiable {
    enum Kind { case user, party }
    let id: String
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let kind: Kind
}

@MainActor
final class NearbyViewModel: ObservableObject {
    @Published var radiusKm: Double = 5
    @Published var people: [ProfileCardModel] = []
    @Published var parties: [FirestoreParty] = []
    @Published var mapPins: [NearbyMapPin] = []
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 18.52, longitude: 73.85),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    @Published var nearbyEnabled = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var locationUnavailable = false
    @Published var categoryFilter: PartyCategory?
    @Published var visibilityFilter: PartyVisibility?
    @Published var showPeoplePins: Bool = true

    /// Coarse current user coordinate (exposed for NearbyMapView)
    private(set) var currentCoordinate: CLLocationCoordinate2D?

    private let social = SocialRepository.shared
    private let location = LocationService.shared
    private let profileRepository = ProfileRepository.shared

    let radiusOptions: [Double] = [1, 5, 10, 25]

    func load() async {
        isLoading = true
        errorMessage = nil
        locationUnavailable = false
        do {
            let profile = try await profileRepository.getUserProfile()
            nearbyEnabled = profile.nearbyEnabled == true
            guard nearbyEnabled else {
                people = []
                parties = []
                mapPins = []
                currentCoordinate = nil
                isLoading = false
                return
            }
            location.requestWhenInUse()
            if location.permissionState == .denied || location.permissionState == .restricted {
                locationUnavailable = true
                isLoading = false
                return
            }
            let coordinate = try await location.requestOneShotLocation()
            try await social.updateLocation(coordinate: coordinate, nearbyEnabled: true)
            let coarse = LocationPrivacy.coarsen(coordinate: coordinate)
            currentCoordinate = coarse
            region = MKCoordinateRegion(
                center: coarse,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
            people = try await social.nearbyPeople(radiusKm: radiusKm, currentCoordinate: coarse)
            var nearbyParties = try await social.nearbyParties(radiusKm: radiusKm, currentCoordinate: coarse)
            if let categoryFilter {
                nearbyParties = nearbyParties.filter { $0.partyCategory == categoryFilter }
            }
            if let visibilityFilter {
                nearbyParties = nearbyParties.filter { $0.partyVisibility == visibilityFilter }
            }
            parties = nearbyParties
            rebuildPins(user: coarse)
        } catch {
            errorMessage = UserFacingError.message(from: error)
            if UserFacingError.message(from: error).lowercased().contains("location") {
                locationUnavailable = true
            }
        }
        isLoading = false
    }

    func setNearbyEnabled(_ enabled: Bool) async {
        do {
            try await social.setNearbyEnabled(enabled)
            nearbyEnabled = enabled
            await load()
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
    }

    func swipe(_ card: ProfileCardModel, like: Bool) async {
        do {
            _ = try await ProfileCardRepository.shared.swipeUser(swipedUserId: card.userId, hasLiked: like)
            people.removeAll { $0.userId == card.userId }
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
    }

    private func rebuildPins(user: CLLocationCoordinate2D) {
        var pins = [
            NearbyMapPin(id: "me", title: "You", subtitle: "Approximate location", coordinate: user, kind: .user)
        ]
        for party in parties {
            if let lat = party.approxLatitude, let lng = party.approxLongitude, let id = party.id {
                pins.append(NearbyMapPin(
                    id: id,
                    title: party.name,
                    subtitle: party.approximateLocation,
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                    kind: .party
                ))
            }
        }
        mapPins = pins
    }
}
