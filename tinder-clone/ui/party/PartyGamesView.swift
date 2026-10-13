import SwiftUI

struct PartyGamesView: View {
    let party: FirestoreParty
    @State private var selectedGame: PartyGameType = .truthOrDare
    @State private var index = 0
    @State private var prompt: GamePrompt = GameEngine.nextPrompt(for: .truthOrDare, index: 0)

    var body: some View {
        VStack(spacing: 16) {
            Picker("Game", selection: $selectedGame) {
                ForEach(PartyGameType.allCases) { game in
                    Text(game.title).tag(game)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 140)
            .onChange(of: selectedGame) { newValue in
                index = 0
                prompt = GameEngine.nextPrompt(for: newValue, index: 0)
            }

            Text(prompt.title)
                .font(.title2.weight(.bold))
            Text(prompt.body)
                .multilineTextAlignment(.center)
                .padding()

            ForEach(prompt.options, id: \.self) { option in
                Button(option) {
                    sendToChat("\(prompt.title): \(option)")
                    next()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.partyColors.first)
            }

            Button("Next prompt") { next() }
            Spacer()
        }
        .padding()
        .navigationTitle("Games")
    }

    private func next() {
        index += 1
        prompt = GameEngine.nextPrompt(for: selectedGame, index: index)
    }

    private func sendToChat(_ text: String) {
        guard let id = party.id else { return }
        try? SocialRepository.shared.sendPartyMessage(partyID: id, text: text, type: .game)
    }
}
