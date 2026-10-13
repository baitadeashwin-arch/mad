import SwiftUI

struct PartyChatView: View {
    let party: FirestoreParty
    @State private var messages: [MessageModel] = []
    @State private var typing = ""
    @State private var errorMessage: String?
    @State private var listenerTask: Task<Void, Never>?

    var body: some View {
        VStack {
            if messages.isEmpty {
                EmptyStateView(
                    systemImage: "bubble.left.and.bubble.right",
                    title: "No messages",
                    message: "Say hi to the party group or drop an ice-breaker."
                )
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack {
                            ForEach(messages) { message in
                                HStack {
                                    if message.isCurrentUser { Spacer() }
                                    VStack(alignment: message.isCurrentUser ? .trailing : .leading) {
                                        if message.type != .text {
                                            Text(message.type.rawValue)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        ContentMessageView(contentMessage: message.message, isCurrentUser: message.isCurrentUser)
                                        Text(message.timestamp.getFormattedDate(format: "h:mm a"))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    if !message.isCurrentUser { Spacer() }
                                }
                                .id(message.id)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .onChange(of: messages) { _ in
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
            }
            HStack {
                TextField("Message the group", text: $typing)
                    .textFieldStyle(.roundedBorder)
                Button("Send") { send(.text) }
                    .disabled(typing.isBlank)
                Menu("More") {
                    Button("AI ice-breaker") { Task { await sendIceBreaker() } }
                }
            }
            .padding()
        }
        .navigationTitle(party.name)
        .alert("Couldn't send", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        ), actions: { Button("OK", role: .cancel) {} }, message: {
            Text(errorMessage ?? "")
        })
        .onAppear { listen() }
        .onDisappear { listenerTask?.cancel() }
    }

    private func listen() {
        guard let id = party.id else { return }
        listenerTask = Task {
            do {
                for try await incoming in SocialRepository.shared.partyMessages(partyID: id) {
                    await MainActor.run { messages = incoming }
                }
            } catch {
                await MainActor.run { errorMessage = UserFacingError.message(from: error) }
            }
        }
    }

    private func send(_ type: SocialMessageType) {
        guard let id = party.id, !typing.isBlank else { return }
        do {
            try SocialRepository.shared.sendPartyMessage(partyID: id, text: typing, type: type)
            typing = ""
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
    }

    private func sendIceBreaker() async {
        guard let id = party.id else { return }
        let text = await AIService.shared.iceBreaker(commonInterests: [])
        do {
            try SocialRepository.shared.sendPartyMessage(partyID: id, text: text, type: .aiIcebreaker)
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
    }
}
