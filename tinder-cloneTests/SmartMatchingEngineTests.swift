//
//  SmartMatchingEngineTests.swift
//  AntiSocialTests
//
//  Created on 16/8/26.
//

import XCTest
@testable import Tinder_Clone

class SmartMatchingEngineTests: XCTestCase {

    func testIdenticalInterests_returns100Percent() {
        let userInterests = ["🎵 Music", "🎬 Movies", "🎮 Gaming"]
        let candidateInterests = ["🎵 Music", "🎬 Movies", "🎮 Gaming"]
        
        let result = SmartMatchingEngine.calculateCompatibility(
            userInterests: userInterests,
            candidateInterests: candidateInterests
        )
        
        XCTAssertEqual(result.score, 100)
        XCTAssertEqual(result.commonInterests.count, 3)
    }

    func testDisjointInterests_returns0Percent() {
        let userInterests = ["🎵 Music", "🎬 Movies"]
        let candidateInterests = ["⚽ Sports", "✈️ Travel"]
        
        let result = SmartMatchingEngine.calculateCompatibility(
            userInterests: userInterests,
            candidateInterests: candidateInterests
        )
        
        XCTAssertEqual(result.score, 0)
        XCTAssertTrue(result.commonInterests.isEmpty)
        XCTAssertEqual(result.conversationStarter, SmartMatchingEngine.defaultStarter)
    }

    func testEmptyInterests_returns0Percent() {
        let userInterests: [String] = []
        let candidateInterests = ["🎵 Music", "🎬 Movies"]
        
        let result = SmartMatchingEngine.calculateCompatibility(
            userInterests: userInterests,
            candidateInterests: candidateInterests
        )
        
        XCTAssertEqual(result.score, 0)
        XCTAssertTrue(result.commonInterests.isEmpty)
    }

    func testWeightedScoreCalculation() {
        // User has: Music (20), Movies (20), Gaming (15) -> Total = 55
        // Candidate has: Music (20), Movies (20), Sports (10) -> Total = 50
        // Shared: Music (20) + Movies (20) -> Shared = 40
        // Score = (2 * 40) / (55 + 50) * 100 = 80 / 105 * 100 = 76.19% -> 76%
        let userInterests = ["🎵 Music", "🎬 Movies", "🎮 Gaming"]
        let candidateInterests = ["🎵 Music", "🎬 Movies", "⚽ Sports"]
        
        let result = SmartMatchingEngine.calculateCompatibility(
            userInterests: userInterests,
            candidateInterests: candidateInterests
        )
        
        XCTAssertEqual(result.score, 76)
        XCTAssertEqual(result.commonInterests.count, 2)
        XCTAssertTrue(result.commonInterests.contains("🎵 Music"))
        XCTAssertTrue(result.commonInterests.contains("🎬 Movies"))
    }

    func testCommonInterests_orderedByWeightDescending() {
        let userInterests = ["📸 Photography", "🎵 Music", "🍕 Food"]
        let candidateInterests = ["🍕 Food", "📸 Photography", "🎵 Music"]
        
        let result = SmartMatchingEngine.calculateCompatibility(
            userInterests: userInterests,
            candidateInterests: candidateInterests
        )
        
        // Music (20) > Food (15) > Photography (8)
        XCTAssertEqual(result.commonInterests.first, "🎵 Music")
        XCTAssertEqual(result.commonInterests[1], "🍕 Food")
        XCTAssertEqual(result.commonInterests.last, "📸 Photography")
    }

    func testDeterministicConversationStarter_gaming() {
        let common = ["🎮 Gaming", "⚽ Sports"]
        let starter = SmartMatchingEngine.generateConversationStarter(commonInterests: common)
        XCTAssertEqual(starter, "You both enjoy gaming. What's your favorite game?")
    }

    func testDeterministicConversationStarter_music() {
        let common = ["🎵 Music", "🍕 Food"]
        let starter = SmartMatchingEngine.generateConversationStarter(commonInterests: common)
        XCTAssertEqual(starter, "You both love music. What's currently on repeat on your playlist?")
    }

    func testNormalization_handlesEmojisAndCaseInsensitive() {
        let weight1 = SmartMatchingEngine.weight(for: "🎵 Music")
        let weight2 = SmartMatchingEngine.weight(for: "music")
        let weight3 = SmartMatchingEngine.weight(for: "MUSIC")
        
        XCTAssertEqual(weight1, 20)
        XCTAssertEqual(weight2, 20)
        XCTAssertEqual(weight3, 20)
    }
}
