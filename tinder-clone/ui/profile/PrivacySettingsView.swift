import SwiftUI

struct PrivacySettingsView: View {
    @State private var nearbyEnabled = false
    @State private var showDistance = true
    @State private var allowInvites = true
    @State private var allowMatchRequests = true
    @State private var errorMessage: String?
    @State private var loaded = false

    var body: some View {
        Form {
            Section("Nearby") {
                Toggle("Nearby Mode", isOn: $nearbyEnabled)
                Toggle("Show me in nearby discovery", isOn: $nearbyEnabled)
                Toggle("Show approximate distance", isOn: $showDistance)
            }
            Section("Social") {
                Toggle("Allow party invitations", isOn: $allowInvites)
                Toggle("Allow match requests", isOn: $allowMatchRequests)
            }
            Text("Nearby Mode uses approximate distance only. Other people never see your exact GPS.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Privacy")
        .task { await load() }
        .onChange(of: nearbyEnabled) { newValue in
            guard loaded else { return }
            Task { await saveNearby(newValue) }
        }
        .onChange(of: showDistance) { _ in Task { await saveFlags() } }
        .onChange(of: allowInvites) { _ in Task { await saveFlags() } }
        .onChange(of: allowMatchRequests) { _ in Task { await saveFlags() } }
        .alert("Couldn't update privacy", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        ), actions: { Button("OK", role: .cancel) {} }, message: {
            Text(errorMessage ?? "")
        })
    }

    private func load() async {
        do {
            let user = try await ProfileRepository.shared.getUserProfile()
            nearbyEnabled = user.nearbyEnabled == true
            showDistance = user.showApproximateDistance ?? true
            allowInvites = user.allowPartyInvitations ?? true
            allowMatchRequests = user.allowMatchRequests ?? true
            loaded = true
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
    }

    private func saveNearby(_ enabled: Bool) async {
        do {
            try await SocialRepository.shared.setNearbyEnabled(enabled)
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
    }

    private func saveFlags() async {
        guard loaded else { return }
        do {
            try await ProfileRepository.shared.updateProfile(modified: [
                FirestoreUser.CodingKeys.showApproximateDistance.rawValue: showDistance,
                FirestoreUser.CodingKeys.allowPartyInvitations.rawValue: allowInvites,
                FirestoreUser.CodingKeys.allowMatchRequests.rawValue: allowMatchRequests,
                FirestoreUser.CodingKeys.updatedAt.rawValue: Date()
            ])
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
    }
}
