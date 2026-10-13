import SwiftUI

struct EventsView: View {
    @StateObject private var viewModel = EventsViewModel()
    @State private var showCreate = false

    var body: some View {
        List {
            Section(header:
                HStack {
                    Text("Invitations")
                    Spacer()
                    if !viewModel.invitations.isEmpty {
                        NavigationLink("View All") {
                            PartyInvitationsView()
                        }
                        .font(.caption)
                    }
                }
            ) {
                if viewModel.invitations.isEmpty {
                    Text("No invitations right now.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(viewModel.invitations.prefix(3)) { invitation in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(invitation.partyName ?? "Party Invitation")
                                        .font(.headline.weight(.semibold))
                                    if let sender = invitation.senderName {
                                        Text("From \(sender)")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                    if let date = invitation.partyDate {
                                        Text(date.getFormattedDate(format: "MMM d, h:mm a"))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "party.popper.fill")
                                    .foregroundColor(AppColor.partyColors.first ?? .purple)
                            }
                            HStack(spacing: 10) {
                                Button("Decline", role: .destructive) {
                                    Task { await viewModel.respond(invitation, accept: false) }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                Button("Accept") {
                                    Task { await viewModel.respond(invitation, accept: true) }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(AppColor.partyColors.first ?? .purple)
                                .controlSize(.small)
                            }
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .contain)
                    }
                    if viewModel.invitations.count > 3 {
                        NavigationLink("See all \(viewModel.invitations.count) invitations") {
                            PartyInvitationsView()
                        }
                        .font(.subheadline)
                    }
                }
            }

            Section("Events & Parties") {
                if viewModel.events.isEmpty {
                    EmptyStateView(
                        systemImage: "calendar.badge.exclamationmark",
                        title: "No events",
                        message: "Create a campus party or event so people can discover it."
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.events) { event in
                        NavigationLink(destination: PartyDetailView(partyID: event.id ?? "")) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.name).font(.headline)
                                Text("\(event.partyCategory.title) · \(event.approximateLocation)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(event.date.getFormattedDate(format: "EEE, MMM d · h:mm a"))
                                    .font(.footnote)
                                Text("\(event.participantCount) going · \(event.partyVisibility.title)")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Events")
        .toolbar {
            Button {
                showCreate = true
            } label: {
                Image(systemName: "plus.circle.fill")
            }
            .accessibilityLabel("Create party")
        }
        .sheet(isPresented: $showCreate) {
            NavigationView {
                CreatePartyView(onCreated: {
                    showCreate = false
                    Task { await viewModel.load() }
                })
            }
        }
        .overlay { if viewModel.isLoading { ProgressView() } }
        .alert("Something went wrong", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        ), actions: { Button("OK", role: .cancel) {} }, message: {
            Text(viewModel.errorMessage ?? "")
        })
        .task { await viewModel.load() }
    }
}
