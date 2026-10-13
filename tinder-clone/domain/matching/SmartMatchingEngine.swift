//
//  SmartMatchingEngine.swift
//  AntiSocial
//
//  Created on 16/8/26.
//

import Foundation

public struct CompatibilityResult: Hashable {
    public let score: Int
    public let commonInterests: [String]
    public let conversationStarter: String
    
    public init(score: Int, commonInterests: [String], conversationStarter: String) {
        self.score = score
        self.commonInterests = commonInterests
        self.conversationStarter = conversationStarter
    }
}

public struct SmartMatchingEngine {
    
    public static let interestWeights: [String: Int] = [
        "music": 20,
        "movies": 20,
        "food": 15,
        "gaming": 15,
        "sports": 10,
        "travel": 10,
        "technology": 10,
        "fitness": 10,
        "photography": 8,
        "art": 8,
        "reading": 8,
        "dance": 8
    ]
    
    public static let conversationStarters: [String: String] = [
        "gaming": "You both enjoy gaming. What's your favorite game?",
        "music": "You both love music. What's currently on repeat on your playlist?",
        "movies": "You both enjoy movies. Seen any great films lately?",
        "food": "You both love food. What's your go-to spot in town?",
        "sports": "You both are into sports. Do you play or follow any teams?",
        "travel": "You both love to travel. Where is your dream destination?",
        "technology": "You both are into technology. What kind of tech projects or gadgets are you into?",
        "fitness": "You both are into fitness. What's your favorite workout routine?",
        "photography": "You both enjoy photography. What do you like shooting the most?",
        "art": "You both appreciate art. What inspires your creative side?",
        "reading": "You both love reading. What book would you recommend?",
        "dance": "You both enjoy dance. What styles of dance do you love?"
    ]
    
    public static let defaultStarter = "Say hello and start the conversation!"
    
    /// Normalizes an interest string by removing emojis, symbols, extra whitespace, and lowercasing.
    public static func normalizeInterest(_ interest: String) -> String {
        let cleaned = interest
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
            .joined()
            .lowercased()
        return cleaned
    }
    
    /// Returns the assigned weight for a given interest string.
    public static func weight(for interest: String) -> Int {
        let normalized = normalizeInterest(interest)
        for (key, weight) in interestWeights {
            if normalized.contains(key) || key.contains(normalized) {
                return weight
            }
        }
        return 5 // Default baseline weight for other interests
    }
    
    /// Calculates the compatibility result between two users based on their selected interests.
    public static func calculateCompatibility(
        userInterests: [String],
        candidateInterests: [String]
    ) -> CompatibilityResult {
        if userInterests.isEmpty || candidateInterests.isEmpty {
            return CompatibilityResult(
                score: 0,
                commonInterests: [],
                conversationStarter: defaultStarter
            )
        }
        
        // Find common interests preserving the candidate's original display string
        var common: [String] = []
        var commonNormalizedSet = Set<String>()
        
        let userNormalizedMap = Dictionary(
            uniqueKeysWithValues: userInterests.map { (normalizeInterest($0), $0) }
        )
        
        for candidateInterest in candidateInterests {
            let normalized = normalizeInterest(candidateInterest)
            if userNormalizedMap[normalized] != nil && !commonNormalizedSet.contains(normalized) {
                common.append(candidateInterest)
                commonNormalizedSet.insert(normalized)
            }
        }
        
        // Sort common interests by weight descending
        common.sort { weight(for: $0) > weight(for: $1) }
        
        // Compute weighted score
        let userTotalWeight = userInterests.reduce(0) { $0 + weight(for: $1) }
        let candidateTotalWeight = candidateInterests.reduce(0) { $0 + weight(for: $1) }
        let sharedWeight = common.reduce(0) { $0 + weight(for: $1) }
        
        let score: Int
        if commonNormalizedSet == Set(userInterests.map(normalizeInterest)) &&
           commonNormalizedSet == Set(candidateInterests.map(normalizeInterest)) {
            score = 100
        } else if userTotalWeight + candidateTotalWeight == 0 || sharedWeight == 0 {
            score = 0
        } else {
            let rawScore = (2.0 * Double(sharedWeight) / Double(userTotalWeight + candidateTotalWeight)) * 100.0
            score = max(0, min(100, Int(rawScore.rounded())))
        }
        
        let starter = generateConversationStarter(commonInterests: common)
        
        return CompatibilityResult(
            score: score,
            commonInterests: common,
            conversationStarter: starter
        )
    }
    
    /// Generates a deterministic conversation starter from the shared common interests.
    public static func generateConversationStarter(commonInterests: [String]) -> String {
        guard let topInterest = commonInterests.first else {
            return defaultStarter
        }
        
        let normalized = normalizeInterest(topInterest)
        for (key, starter) in conversationStarters {
            if normalized.contains(key) || key.contains(normalized) {
                return starter
            }
        }
        
        return "You both enjoy \(topInterest). What's your favorite part about it?"
    }
}
