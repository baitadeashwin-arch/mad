import SwiftUI

struct PartyDetailView: View {
    let partyID: String
    @State private var party: FirestoreParty?
    @State private var isMember = false
    @State private var privateNote: String?
    @State private var participants: [PartyParticipantPreview] = []
    @State private var matches: [MatchModel] = []
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var showInvite = false
    @State private var selectedParticipant: PartyParticipantPreview?
    @State private var iceBreaker: String?
    @State private var connectedUserIds: Set<String> = []

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let party {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(party.name).font(.largeTitle.weight(.bold))
                        Text(party.description)
                        if let host = party.hostName, !host.isEmpty {
                            labeled("Host", host)
                        }
                        labeled("When", party.date.getFormattedDate(format: "EEEE, MMM d · h:mm a"))
                        labeled("Where", party.approximateLocation)
                        if isMember, let privateNote, !privateNote.isEmpty {
                            labeled("Members-only note", privateNote)
                        } else if party.partyVisibility == .inviteOnly && !isMember {
                            Text("Exact location is hidden until you join.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        labeled("Hosted as", party.partyCategory.title)
                        labeled("Visibility", party.partyVisibility.title)
                        Text("\(party.participantCount) people going")
                            .font(.headline)

                        if let iceBreaker {
                            Text(iceBreaker)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                        }

                        HStack {
                            if isMember {
                                Button("Leave") { Task { await leave() } }
                                    .buttonStyle(.bordered)
                                NavigationLink("Open Party Group") {
                                    PartyGroupView(party: party)
                                }
                                .buttonStyle(.borderedProminent)
                                Button("Invite") { showInvite = true }
                            } else {
                                Button("Join") { Task { await join() } }
                                    .buttonStyle(.borderedProminent)
                            }
                        }

                        Text("People going")
                            .font(.title3.weight(.bold))
                        if participants.isEmpty {
                            EmptyStateView(
                                systemImage: "person.3",
                                title: "No party participants",
                                message: "Be the first friend to join."
                            )
                            .frame(height: 160)
                        } else {
                            ForEach(participants) { person in
                                participantRow(person)
                            }
                        }
                    }
                    .padding()
                }
            } else {
                EmptyStateView(
                    systemImage: "exclamationmark.triangle",
                    title: "Party unavailable",
                    message: "This event may be private or no longer listed."
                )
            }
        }
        .navigationTitle("Party")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showInvite) {
            InviteMatchesView(matches: matches) { match in
                Task { await invite(match) }
            }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        ), actions: { Button("OK", role: .cancel) {} }, message: {
            Text(errorMessage ?? "")
        })
        .task { await load() }
    }

    private func participantRow(_ person: PartyParticipantPreview) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if let photo = person.picture {
                Image(uiImage: photo).centerCropped().frame(width: 52, height: 52).cornerRadius(26)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 52, height: 52)
                    .foregroundColor(.secondary)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(person.name).font(.headline)
                if let college = person.college {
                    Text(college)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                if let score = person.score {
                    Text("🔥 \(score.total)% Match")
                        .font(.caption.weight(.bold))
                        .foregroundColor(AppColor.partyColors.first ?? .purple)
                }
                if !person.commonInterests.isEmpty {
                    Text("Common: \(person.commonInterests.prefix(3).joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("You're both going to this party 🎉")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(AppColor.partyColors.first ?? .purple)
            }
            Spacer()
            if connectedUserIds.contains(person.id) {
                Text("Connected ✓")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(12)
            } else {
                Button("Connect") {
                    Task {
                        try? await ProfileCardRepository.shared.swipeUser(swipedUserId: person.id, hasLiked: true)
                        connectedUserIds.insert(person.id)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.appColors.first ?? .blue)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(14)
        .padding(.vertical, 2)
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value).font(.body.weight(.medium))
        }
    }

    private func load() async {
        isLoading = true
        do {
            party = try await SocialRepository.shared.party(id: partyID)
            isMember = try await SocialRepository.shared.isMember(partyID: partyID)
            if isMember {
                privateNote = try? await SocialRepository.shared.privateLocation(partyID: partyID)
            }
            participants = try await SocialRepository.shared.participants(partyID: partyID)
            matches = try await SocialRepository.shared.matchesForInvite()
            iceBreaker = await AIService.shared.activitySuggestion(
                commonInterests: participants.first?.commonInterests ?? [],
                partyName: party?.name
            )
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
        isLoading = false
    }

    private func join() async {
        guard let party else { return }
        do {
            try await SocialRepository.shared.join(party: party)
            await load()
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
    }

    private func leave() async {
        do {
            try await SocialRepository.shared.leave(partyID: partyID)
            await load()
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
    }

    private func invite(_ match: MatchModel) async {
        do {
            try await SocialRepository.shared.invite(partyID: partyID, receiverID: match.userId)
            showInvite = false
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
    }
}

struct InviteMatchesView: View {
    let matches: [MatchModel]
    let onInvite: (MatchModel) -> Void

    var body: some View {
        NavigationView {
            List(matches) { match in
                Button {
                    onInvite(match)
                } label: {
                    HStack {
                        Image(uiImage: match.picture).centerCropped().frame(width: 40, height: 40).cornerRadius(20)
                        Text(match.name)
                    }
                }
            }
            .navigationTitle("Invite matches")
        }
    }
}

struct PartyGroupView: View {
    let party: FirestoreParty

    var body: some View {
        List {
            NavigationLink("Group chat") {
                PartyChatView(party: party)
            }
            NavigationLink("Party games") {
                PartyGamesView(party: party)
            }
            NavigationLink("People going") {
                PartyDetailView(partyID: party.id ?? "")
            }
        }
        .navigationTitle("Party Mode")
    }
}
