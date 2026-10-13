import SwiftUI
import MapKit
import CoreLocation

// MARK: - NearbyView

struct NearbyView: View {
    @StateObject private var viewModel = NearbyViewModel()
    @State private var selectedPerson: ProfileCardModel?
    @State private var selectedParty: FirestoreParty?
    @State private var showLocationPermissionSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // ── Nearby Mode Toggle ──────────────────────────────────
                Toggle("Nearby Mode", isOn: Binding(
                    get: { viewModel.nearbyEnabled },
                    set: { newValue in
                        if newValue, LocationService.shared.permissionState == .notDetermined {
                            showLocationPermissionSheet = true
                        } else {
                            Task { await viewModel.setNearbyEnabled(newValue) }
                        }
                    }
                ))
                .accessibilityLabel("Nearby Mode")
                .padding(.horizontal)

                // ── Location unavailable ────────────────────────────────
                if viewModel.locationUnavailable {
                    EmptyStateView(
                        systemImage: "location.slash",
                        title: "Location unavailable",
                        message: "AntiSocial still works. Enable location in Settings → Privacy → Location Services to find people and parties nearby."
                    )
                    .frame(height: 220)

                // ── Nearby Mode is OFF ──────────────────────────────────
                } else if !viewModel.nearbyEnabled {
                    EmptyStateView(
                        systemImage: "location.circle",
                        title: "Nearby Mode is off",
                        message: "Turn it on to discover compatible people and parties around you. You will not appear in nearby discovery while this is off.",
                        actionTitle: "Enable Nearby",
                        action: {
                            if LocationService.shared.permissionState == .notDetermined {
                                showLocationPermissionSheet = true
                            } else {
                                Task { await viewModel.setNearbyEnabled(true) }
                            }
                        }
                    )
                    .frame(height: 260)

                // ── Nearby Mode ON ──────────────────────────────────────
                } else {
                    // Rich MapKit map
                    NearbyMapView(
                        region: $viewModel.region,
                        currentUserCoordinate: viewModel.currentCoordinate,
                        parties: viewModel.parties,
                        people: viewModel.people,
                        radiusKm: viewModel.radiusKm,
                        showPeoplePins: $viewModel.showPeoplePins,
                        onSelectParty: { party in selectedParty = party },
                        onSelectPerson: { person in selectedPerson = person }
                    )
                    .frame(height: 240)
                    .padding(.horizontal)

                    // ── Distance filter ─────────────────────────────────
                    Picker("Distance", selection: $viewModel.radiusKm) {
                        ForEach(viewModel.radiusOptions, id: \.self) { value in
                            Text("\(Int(value)) km").tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: viewModel.radiusKm) { _ in
                        Task { await viewModel.load() }
                    }
                    .accessibilityLabel("Distance filter")

                    // ── Summary counts ──────────────────────────────────
                    Text("\(viewModel.people.count) compatible people within \(Int(viewModel.radiusKm)) km.")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal)
                    Text("\(viewModel.parties.count) parties nearby.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    // ── Nearby People ───────────────────────────────────
                    sectionHeader("Nearby People")
                    if viewModel.people.isEmpty {
                        EmptyStateView(
                            systemImage: "person.2.slash",
                            title: "No nearby people",
                            message: "Try a larger distance or check back after more students enable Nearby Mode."
                        )
                        .frame(height: 180)
                    } else {
                        ForEach(viewModel.people, id: \.userId) { person in
                            NearbyPersonCard(person: person, onLike: {
                                Task { await viewModel.swipe(person, like: true) }
                            }, onPass: {
                                Task { await viewModel.swipe(person, like: false) }
                            }, onView: {
                                selectedPerson = person
                            })
                            .padding(.horizontal)
                        }
                    }

                    // ── Nearby Parties ──────────────────────────────────
                    sectionHeader("Nearby Parties")
                    partyFilters
                    if viewModel.parties.isEmpty {
                        EmptyStateView(
                            systemImage: "party.popper",
                            title: "No nearby parties",
                            message: "Create a public event or widen the distance filter."
                        )
                        .frame(height: 180)
                    } else {
                        ForEach(viewModel.parties) { party in
                            NavigationLink(destination: PartyDetailView(partyID: party.id ?? "")) {
                                NearbyPartyCard(party: party, userCoordinate: viewModel.region.center)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle("Nearby")
        .overlay {
            if viewModel.isLoading { ProgressView() }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        ), actions: { Button("OK", role: .cancel) {} }, message: {
            Text(viewModel.errorMessage ?? "")
        })
        .sheet(item: $selectedPerson) { person in
            PersonPreviewView(person: person)
        }
        .sheet(item: $selectedParty) { party in
            NavigationView {
                PartyDetailView(partyID: party.id ?? "")
            }
        }
        .sheet(isPresented: $showLocationPermissionSheet) {
            LocationPermissionView(onGrant: {
                showLocationPermissionSheet = false
                LocationService.shared.requestWhenInUse()
                Task { await viewModel.setNearbyEnabled(true) }
            }, onDeny: {
                showLocationPermissionSheet = false
            })
        }
        .task { await viewModel.load() }
    }

    // MARK: Helpers

    private var partyFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                filterChip("All", selected: viewModel.categoryFilter == nil) {
                    viewModel.categoryFilter = nil
                    Task { await viewModel.load() }
                }
                ForEach(PartyCategory.allCases) { category in
                    filterChip(category.title, selected: viewModel.categoryFilter == category) {
                        viewModel.categoryFilter = category
                        Task { await viewModel.load() }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selected ? AppColor.appColors.first : Color(UIColor.secondarySystemBackground))
                .foregroundColor(selected ? .white : .primary)
                .cornerRadius(12)
        }
        .accessibilityLabel(title)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.bold))
            .padding(.horizontal)
            .padding(.top, 8)
    }
}

// MARK: - NearbyPersonCard

struct NearbyPersonCard: View {
    let person: ProfileCardModel
    let onLike: () -> Void
    let onPass: () -> Void
    let onView: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                if let photo = person.pictures.first {
                    Image(uiImage: photo)
                        .centerCropped()
                        .frame(width: 72, height: 72)
                        .cornerRadius(12)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("🔥 \(person.compatibilityScore ?? 0)% Match")
                        .font(.caption.weight(.bold))
                        .foregroundColor(AppColor.partyColors.first)
                    Text("\(person.name), \(person.age)")
                        .font(.headline)
                    if let college = person.college {
                        Text(college).font(.subheadline).foregroundColor(.secondary)
                    }
                    if let distance = person.approximateDistanceText {
                        Text(distance).font(.footnote).foregroundColor(.secondary)
                    }
                    if let mode = person.connectionMode {
                        Text(mode.titleKey)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(mode == .party ? AppColor.partyColors.first : AppColor.friendColors.first)
                            .cornerRadius(6)
                    }
                    if let interests = person.commonInterests, !interests.isEmpty {
                        Text("Common: \(interests.prefix(3).joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let banner = person.matchScore?.samePartyBanner {
                        Text(banner)
                            .font(.caption2.weight(.medium))
                            .foregroundColor(AppColor.partyColors.first ?? .purple)
                    }
                }
                Spacer()
            }
            HStack {
                Button("Pass", action: onPass)
                    .buttonStyle(.bordered)
                Button("Like", action: onLike)
                    .buttonStyle(.borderedProminent)
                    .tint(AppColor.likeColors.first)
                Button("View Profile", action: onView)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - NearbyPartyCard

struct NearbyPartyCard: View {
    let party: FirestoreParty
    let userCoordinate: CLLocationCoordinate2D

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(party.name).font(.headline)
                Spacer()
                Text(party.partyVisibility.title)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(8)
            }
            Text(distanceText)
                .font(.subheadline)
                .foregroundColor(.secondary)
            if let host = party.hostName, !host.isEmpty {
                Text("Host: \(host)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Text(party.date.getFormattedDate(format: "MMM d, h:mm a"))
                .font(.footnote)
            Text("\(party.partyCategory.title) · \(party.participantCount) people going")
                .font(.footnote)
            Text(party.approximateLocation)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var distanceText: String {
        LocationPrivacy.distanceLabel(
            kilometers: LocationPrivacy.approximateDistanceKilometers(
                fromLatitude: userCoordinate.latitude,
                fromLongitude: userCoordinate.longitude,
                toLatitude: party.approxLatitude,
                toLongitude: party.approxLongitude
            ),
            collegeHint: party.college
        )
    }
}

// MARK: - PersonPreviewView

struct PersonPreviewView: View {
    let person: ProfileCardModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let photo = person.pictures.first {
                        Image(uiImage: photo)
                            .centerCropped()
                            .frame(height: 320)
                    }
                    DiscoverMetaView(model: person)
                        .padding()
                }
            }
            .navigationTitle(person.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - LocationPermissionView

struct LocationPermissionView: View {
    let onGrant: () -> Void
    let onDeny: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "location.circle.fill")
                .font(.system(size: 72))
                .foregroundGradient(colors: AppColor.appColors)

            Text("Nearby Mode")
                .font(.title.weight(.bold))

            Text("Nearby Mode uses your **approximate** location to show compatible people, parties and events around you.\n\nYour **exact GPS is never shown** to anyone — we only use a rough area (±1 km).")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                featureBullet(icon: "person.2.fill", text: "Discover compatible people nearby")
                featureBullet(icon: "party.popper.fill", text: "Find parties and events close to you")
                featureBullet(icon: "eye.slash.fill", text: "Your exact location is never visible to others")
                featureBullet(icon: "togglepower", text: "You can turn Nearby Mode off anytime")
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onGrant) {
                    Text("Enable Nearby Mode")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(colors: AppColor.appColors, startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)

                Button("Not now", action: onDeny)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 32)
        }
        .accessibilityElement(children: .contain)
    }

    private func featureBullet(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColor.appColors.first)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
        }
    }
}
