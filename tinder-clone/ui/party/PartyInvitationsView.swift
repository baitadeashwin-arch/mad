import SwiftUI
import CoreLocation

@MainActor
final class PartyInvitationsViewModel: ObservableObject {
    @Published var invitations: [FirestorePartyInvitation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userCoordinate: CLLocationCoordinate2D?

    private let social = SocialRepository.shared
    private let locationService = LocationService.shared

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            if locationService.permissionState == .authorized {
                userCoordinate = try? await locationService.requestOneShotLocation()
            }
            invitations = try await social.invitations()
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
        isLoading = false
    }

    func respond(_ invitation: FirestorePartyInvitation, accept: Bool) async {
        do {
            try await social.respond(invitation: invitation, accept: accept)
            invitations.removeAll { $0.id == invitation.id }
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
    }
}

struct PartyInvitationsView: View {
    @StateObject private var viewModel = PartyInvitationsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.invitations.isEmpty {
                EmptyStateView(
                    systemImage: "envelope.open",
                    title: "No invitations",
                    message: "When your matches or campus friends invite you to parties, they will show up here."
                )
                .padding()
            } else {
                List {
                    ForEach(viewModel.invitations) { invitation in
                        PartyInvitationCard(
                            invitation: invitation,
                            userCoordinate: viewModel.userCoordinate,
                            onAccept: {
                                Task { await viewModel.respond(invitation, accept: true) }
                            },
                            onDecline: {
                                Task { await viewModel.respond(invitation, accept: false) }
                            }
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Party Invitations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.load() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        ), actions: { Button("OK", role: .cancel) {} }, message: {
            Text(viewModel.errorMessage ?? "")
        })
        .task {
            await viewModel.load()
        }
    }
}

struct PartyInvitationCard: View {
    let invitation: FirestorePartyInvitation
    let userCoordinate: CLLocationCoordinate2D?
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invitation.partyName ?? "Party Invitation")
                        .font(.headline.weight(.bold))
                    if let sender = invitation.senderName {
                        Text("Invited by \(sender)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "party.popper.fill")
                    .foregroundColor(AppColor.partyColors.first ?? .purple)
                    .font(.title3)
            }

            Divider()

            HStack(spacing: 16) {
                if let date = invitation.partyDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(date.getFormattedDate(format: "MMM d, h:mm a"))
                            .font(.caption.weight(.medium))
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(distanceText)
                        .font(.caption.weight(.medium))
                }
            }

            HStack(spacing: 12) {
                Button(action: onDecline) {
                    Text("Decline")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)

                Button(action: onAccept) {
                    Text("Accept")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.partyColors.first ?? .purple)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .accessibilityElement(children: .contain)
    }

    private var distanceText: String {
        guard let userCoordinate,
              let lat = invitation.approxLatitude,
              let lng = invitation.approxLongitude else {
            return "Distance unavailable"
        }
        let km = LocationPrivacy.approximateDistanceKilometers(
            fromLatitude: userCoordinate.latitude,
            fromLongitude: userCoordinate.longitude,
            toLatitude: lat,
            toLongitude: lng
        )
        return LocationPrivacy.distanceLabel(kilometers: km)
    }
}
