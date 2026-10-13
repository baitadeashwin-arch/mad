import Foundation

@MainActor
final class EventsViewModel: ObservableObject {
    @Published var events: [FirestoreParty] = []
    @Published var invitations: [FirestorePartyInvitation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let social = SocialRepository.shared

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            events = try await social.parties(isEvent: nil)
            invitations = try await social.invitations()
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
        isLoading = false
    }

    func respond(_ invitation: FirestorePartyInvitation, accept: Bool) async {
        do {
            try await social.respond(invitation: invitation, accept: accept)
            await load()
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
    }
}
