//
//  AIService.swift
//  AntiSocial
//
//  Never hardcode API keys. Falls back to local suggestions.
//

import Foundation

protocol AIServiceProtocol {
    func conversationStarter(commonInterests: [String], sharedPartyName: String?) async -> String
    func iceBreaker(commonInterests: [String]) async -> String
    func activitySuggestion(commonInterests: [String], partyName: String?) async -> String
    func partySuggestion(interests: [String], college: String?) async -> String
    func commonInterestQuestion(commonInterests: [String]) async -> String
    func explainMatch(score: MatchScore) async -> String
}

enum AIServiceFactory {
    static func make() -> AIServiceProtocol {
        if let endpoint = Bundle.main.object(forInfoDictionaryKey: "ANTISOCIAL_AI_ENDPOINT") as? String,
           !endpoint.isEmpty {
            return RemoteAIService(endpoint: endpoint)
        }
        return LocalAIService()
    }
}

struct LocalAIService: AIServiceProtocol {
    func conversationStarter(commonInterests: [String], sharedPartyName: String?) async -> String {
        if let sharedPartyName {
            return "You're both going to \(sharedPartyName). What are you most excited about?"
        }
        return SmartMatchingEngine.generateConversationStarter(commonInterests: commonInterests)
    }

    func iceBreaker(commonInterests: [String]) async -> String {
        commonInterestQuestion(from: commonInterests)
    }

    func activitySuggestion(commonInterests: [String], partyName: String?) async -> String {
        let interest = commonInterests.first ?? "campus life"
        if let partyName {
            return "At \(partyName), try a \(interest.lowercased()) challenge with people you just met."
        }
        return "Plan a low-key meetup around \(interest.lowercased()) this week."
    }

    func partySuggestion(interests: [String], college: String?) async -> String {
        let campus = college?.isEmpty == false ? college! : "campus"
        if interests.contains(where: { SmartMatchingEngine.normalizeInterest($0).contains("gaming") }) {
            return "A \(campus) gaming night would fit your interests."
        }
        if interests.contains(where: { SmartMatchingEngine.normalizeInterest($0).contains("music") }) {
            return "Look for a music night near \(campus)."
        }
        return "Browse public events near \(campus) that match your interests."
    }

    func commonInterestQuestion(commonInterests: [String]) async -> String {
        commonInterestQuestion(from: commonInterests)
    }

    func explainMatch(score: MatchScore) async -> String {
        var parts: [String] = ["Compatibility is \(score.total)%."]
        if !score.commonInterests.isEmpty {
            parts.append("You share \(score.commonInterests.prefix(3).joined(separator: ", ")).")
        }
        for reason in score.reasons {
            parts.append("✓ \(reason.title)")
        }
        return parts.joined(separator: " ")
    }

    private func commonInterestQuestion(from interests: [String]) -> String {
        if interests.count >= 2 {
            return "You both enjoy \(interests[0]) and \(interests[1]). What's the last \(interests[0].lowercased()) thing you tried?"
        }
        return SmartMatchingEngine.generateConversationStarter(commonInterests: interests)
    }
}

/// Optional remote AI. Endpoint is read from Info.plist / xcconfig, never from source secrets.
struct RemoteAIService: AIServiceProtocol {
    let endpoint: String
    private let fallback = LocalAIService()

    func conversationStarter(commonInterests: [String], sharedPartyName: String?) async -> String {
        await fallback.conversationStarter(commonInterests: commonInterests, sharedPartyName: sharedPartyName)
    }

    func iceBreaker(commonInterests: [String]) async -> String {
        await fallback.iceBreaker(commonInterests: commonInterests)
    }

    func activitySuggestion(commonInterests: [String], partyName: String?) async -> String {
        await fallback.activitySuggestion(commonInterests: commonInterests, partyName: partyName)
    }

    func partySuggestion(interests: [String], college: String?) async -> String {
        await fallback.partySuggestion(interests: interests, college: college)
    }

    func commonInterestQuestion(commonInterests: [String]) async -> String {
        await fallback.commonInterestQuestion(commonInterests: commonInterests)
    }

    func explainMatch(score: MatchScore) async -> String {
        await fallback.explainMatch(score: score)
    }
}

struct AIService {
    static let shared: AIServiceProtocol = AIServiceFactory.make()
}
