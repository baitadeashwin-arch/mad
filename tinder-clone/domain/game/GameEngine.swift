//
//  GameEngine.swift
//  AntiSocial
//

import Foundation

enum PartyGameType: String, CaseIterable, Identifiable {
    case truthOrDare
    case wouldYouRather
    case personalityQuiz
    case twoTruthsAndALie
    case commonInterestChallenge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .truthOrDare: return "Truth or Dare"
        case .wouldYouRather: return "Would You Rather"
        case .personalityQuiz: return "Quick Personality Quiz"
        case .twoTruthsAndALie: return "Two Truths and a Lie"
        case .commonInterestChallenge: return "Common Interest Challenge"
        }
    }
}

struct GamePrompt: Identifiable, Equatable {
    let id: String
    let title: String
    let body: String
    let options: [String]
}

struct GameEngine {
    static func nextPrompt(for type: PartyGameType, commonInterests: [String] = [], index: Int) -> GamePrompt {
        let prompts = prompts(for: type, commonInterests: commonInterests)
        let safeIndex = prompts.isEmpty ? 0 : abs(index) % max(prompts.count, 1)
        return prompts[safeIndex]
    }

    static func prompts(for type: PartyGameType, commonInterests: [String]) -> [GamePrompt] {
        switch type {
        case .truthOrDare:
            return [
                GamePrompt(id: "td1", title: "Truth", body: "What's a campus tradition you secretly love?", options: ["Truth", "Dare"]),
                GamePrompt(id: "td2", title: "Dare", body: "Introduce yourself to someone new in this party group.", options: ["Truth", "Dare"]),
                GamePrompt(id: "td3", title: "Truth", body: "Which interest on your profile is the most accurate?", options: ["Truth", "Dare"])
            ]
        case .wouldYouRather:
            return [
                GamePrompt(id: "wyr1", title: "Would You Rather", body: "Late-night food run or sunrise hangout?", options: ["Food run", "Sunrise"]),
                GamePrompt(id: "wyr2", title: "Would You Rather", body: "House party playlist DJ or party photographer?", options: ["DJ", "Photographer"]),
                GamePrompt(id: "wyr3", title: "Would You Rather", body: "Board games night or outdoor sports meetup?", options: ["Board games", "Sports"])
            ]
        case .personalityQuiz:
            return [
                GamePrompt(id: "q1", title: "Quiz", body: "Your ideal Friday is...", options: ["Chill hangout", "Packed party", "Creative project"]),
                GamePrompt(id: "q2", title: "Quiz", body: "In a group you usually...", options: ["Host", "Connect people", "Observe then jump in"])
            ]
        case .twoTruthsAndALie:
            return [
                GamePrompt(id: "ttl1", title: "Two Truths and a Lie", body: "Share two true campus stories and one fake. Let the group guess the lie.", options: ["I guessed", "That was me"])
            ]
        case .commonInterestChallenge:
            let interest = commonInterests.first ?? "shared hobbies"
            return [
                GamePrompt(id: "cic1", title: "Challenge", body: "You both care about \(interest). Name a related activity you could try this month.", options: ["Done"]),
                GamePrompt(id: "cic2", title: "Challenge", body: "Find one song, game, or food that everyone in the group enjoys.", options: ["Found it"])
            ]
        }
    }
}
