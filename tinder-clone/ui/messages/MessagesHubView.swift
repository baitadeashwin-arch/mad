import SwiftUI

struct MessagesHubView: View {
    @StateObject private var matchesViewModel = MatchListViewModel()
    @State private var parties: [FirestoreParty] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Matches") {
                if matchesViewModel.isLoading {
                    ProgressView()
                } else if matchesViewModel.matchModels.isEmpty {
                    Text("No matches yet. Keep discovering people.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(matchesViewModel.matchModels) { match in
                        NavigationLink(destination: ChatView(match: match)) {
                            MatchItemView(model: match)
                        }
                        .swipeActions {
                            Button("Unmatch", role: .destructive) {
                                Task { try? await SocialRepository.shared.unmatch(matchId: match.id) }
                            }
                            Button("Block") {
                                Task { try? await SocialRepository.shared.block(userId: match.userId) }
                            }
                        }
                    }
                }
            }
            Section("Party chats") {
                if parties.isEmpty {
                    Text("Join a party to open a group chat.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(parties) { party in
                        NavigationLink(destination: PartyChatView(party: party)) {
                            VStack(alignment: .leading) {
                                Text(party.name).font(.headline)
                                Text("\(party.participantCount) members")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Messages")
        .task {
            matchesViewModel.fetchMatches()
            do {
                parties = try await SocialRepository.shared.myParties()
            } catch {
                errorMessage = UserFacingError.message(from: error)
            }
        }
        .alert("Couldn't load messages", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        ), actions: { Button("OK", role: .cancel) {} }, message: {
            Text(errorMessage ?? "")
        })
    }
}
