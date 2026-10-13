import SwiftUI
import MapKit

// MARK: - Map Annotations

final class UserPinAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?

    init(coordinate: CLLocationCoordinate2D, title: String? = "You", subtitle: String? = "Approximate Location") {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        super.init()
    }
}

final class PartyMapAnnotation: NSObject, MKAnnotation {
    let party: FirestoreParty
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?

    init(party: FirestoreParty, coordinate: CLLocationCoordinate2D, distanceText: String?) {
        self.party = party
        self.coordinate = coordinate
        self.title = party.name
        self.subtitle = [party.partyCategory.title, distanceText].compactMap { $0 }.joined(separator: " · ")
        super.init()
    }
}

final class PersonMapAnnotation: NSObject, MKAnnotation {
    let person: ProfileCardModel
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?

    init(person: ProfileCardModel, coordinate: CLLocationCoordinate2D) {
        self.person = person
        self.coordinate = coordinate
        self.title = "\(person.name), \(person.age)"
        self.subtitle = [person.college, person.approximateDistanceText].compactMap { $0 }.joined(separator: " · ")
        super.init()
    }
}

// MARK: - NearbyMapView

struct NearbyMapView: View {
    @Binding var region: MKCoordinateRegion
    let currentUserCoordinate: CLLocationCoordinate2D?
    let parties: [FirestoreParty]
    let people: [ProfileCardModel]
    let radiusKm: Double
    @Binding var showPeoplePins: Bool
    var onSelectParty: ((FirestoreParty) -> Void)?
    var onSelectPerson: ((ProfileCardModel) -> Void)?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            NearbyMapKitRepresentable(
                region: $region,
                currentUserCoordinate: currentUserCoordinate,
                parties: parties,
                people: people,
                radiusKm: radiusKm,
                showPeoplePins: showPeoplePins,
                onSelectParty: onSelectParty,
                onSelectPerson: onSelectPerson
            )
            .cornerRadius(18)

            // Map overlay controls
            VStack(alignment: .trailing, spacing: 8) {
                Button(action: recenter) {
                    Image(systemName: "location.fill")
                        .font(.body.weight(.semibold))
                        .foregroundColor(AppColor.appColors.first ?? .blue)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
                .accessibilityLabel("Recenter map on your approximate location")

                Button(action: { showPeoplePins.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: showPeoplePins ? "person.2.fill" : "person.2.slash")
                        Text(showPeoplePins ? "People ON" : "People OFF")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
                .accessibilityLabel(showPeoplePins ? "Hide people pins on map" : "Show people pins on map")
            }
            .padding(12)
        }
    }

    private func recenter() {
        guard let center = currentUserCoordinate else { return }
        withAnimation {
            region = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        }
    }
}

// MARK: - MapKit UIKit Representable

struct NearbyMapKitRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let currentUserCoordinate: CLLocationCoordinate2D?
    let parties: [FirestoreParty]
    let people: [ProfileCardModel]
    let radiusKm: Double
    let showPeoplePins: Bool
    var onSelectParty: ((FirestoreParty) -> Void)?
    var onSelectPerson: ((ProfileCardModel) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parent = self

        // Update annotations
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        var annotations: [MKAnnotation] = []

        // User coarse location
        if let userCoord = currentUserCoordinate {
            annotations.append(UserPinAnnotation(coordinate: userCoord))

            // Radius circle overlay (in meters)
            let circle = MKCircle(center: userCoord, radius: radiusKm * 1000.0)
            mapView.addOverlay(circle)
        }

        // Party annotations
        for party in parties {
            if let lat = party.approxLatitude, let lng = party.approxLongitude {
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                let distanceKm = LocationPrivacy.approximateDistanceKilometers(
                    fromLatitude: currentUserCoordinate?.latitude,
                    fromLongitude: currentUserCoordinate?.longitude,
                    toLatitude: lat,
                    toLongitude: lng
                )
                let distanceText = LocationPrivacy.distanceLabel(kilometers: distanceKm, collegeHint: party.college)
                annotations.append(PartyMapAnnotation(party: party, coordinate: coord, distanceText: distanceText))
            }
        }

        // Approximate people annotations (optional & clusterable)
        if showPeoplePins, let userCoord = currentUserCoordinate {
            for person in people {
                if let km = person.matchScore?.approximateDistanceKilometers, km <= radiusKm {
                    // Safe coarse coordinate with subtle privacy jitter (< 200m)
                    let jitterCoord = disperseCoordinate(around: userCoord, id: person.userId, distanceKm: km)
                    annotations.append(PersonMapAnnotation(person: person, coordinate: jitterCoord))
                }
            }
        }

        mapView.addAnnotations(annotations)
    }

    private func disperseCoordinate(around center: CLLocationCoordinate2D, id: String, distanceKm: Double) -> CLLocationCoordinate2D {
        let hash = abs(id.hashValue)
        let angle = Double(hash % 360) * (.pi / 180.0)
        let radiusDeg = (max(0.2, distanceKm) / 111.0)
        let lat = center.latitude + (radiusDeg * sin(angle))
        let lng = center.longitude + ((radiusDeg / cos(center.latitude * (.pi / 180.0))) * cos(angle))
        return LocationPrivacy.coarsen(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng))
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: NearbyMapKitRepresentable

        init(_ parent: NearbyMapKitRepresentable) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let userAnnotation = annotation as? UserPinAnnotation {
                let id = "UserPin"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                if view == nil {
                    view = MKMarkerAnnotationView(annotation: userAnnotation, reuseIdentifier: id)
                    view?.canShowCallout = true
                } else {
                    view?.annotation = userAnnotation
                }
                view?.markerTintColor = UIColor(AppColor.appColors.first ?? .blue)
                view?.glyphImage = UIImage(systemName: "person.crop.circle.fill")
                view?.clusteringIdentifier = nil
                view?.displayPriority = .required
                return view
            }

            if let partyAnnotation = annotation as? PartyMapAnnotation {
                let id = "PartyPin"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                if view == nil {
                    view = MKMarkerAnnotationView(annotation: partyAnnotation, reuseIdentifier: id)
                    view?.canShowCallout = true
                    view?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                } else {
                    view?.annotation = partyAnnotation
                }
                view?.markerTintColor = UIColor(AppColor.partyColors.first ?? .purple)
                view?.glyphImage = UIImage(systemName: "party.popper.fill")
                view?.clusteringIdentifier = "partiesCluster"
                view?.displayPriority = .defaultHigh
                return view
            }

            if let personAnnotation = annotation as? PersonMapAnnotation {
                let id = "PersonPin"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                if view == nil {
                    view = MKMarkerAnnotationView(annotation: personAnnotation, reuseIdentifier: id)
                    view?.canShowCallout = true
                    view?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                } else {
                    view?.annotation = personAnnotation
                }
                view?.markerTintColor = UIColor(AppColor.likeColors.first ?? .systemPink)
                view?.glyphImage = UIImage(systemName: "person.fill")
                view?.clusteringIdentifier = "peopleCluster"
                view?.displayPriority = .defaultLow
                return view
            }

            if let cluster = annotation as? MKClusterAnnotation {
                let id = "ClusterPin"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                if view == nil {
                    view = MKMarkerAnnotationView(annotation: cluster, reuseIdentifier: id)
                    view?.canShowCallout = true
                } else {
                    view?.annotation = cluster
                }
                view?.markerTintColor = UIColor.systemIndigo
                return view
            }

            return nil
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circleOverlay = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circleOverlay)
                renderer.fillColor = UIColor.systemIndigo.withAlphaComponent(0.08)
                renderer.strokeColor = UIColor.systemIndigo.withAlphaComponent(0.35)
                renderer.lineWidth = 1.5
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            if let partyAnnotation = view.annotation as? PartyMapAnnotation {
                parent.onSelectParty?(partyAnnotation.party)
            } else if let personAnnotation = view.annotation as? PersonMapAnnotation {
                parent.onSelectPerson?(personAnnotation.person)
            }
        }
    }
}
