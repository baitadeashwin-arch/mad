//
//  MatchEngine.swift
//  AntiSocial
//
//  Deterministic local matching. AI never owns the primary score.
//

import Foundation
import CoreLocation

public enum MatchReason: String, Hashable, Codable, CaseIterable {
    case commonInterests
    case nearby
    case sameCollege
    case sameParty
    case sameConnectionMode

    public var title: String {
        switch self {
        case .commonInterests: return "Common interests"
        case .nearby: return "Nearby"
        case .sameCollege: return "Same college"
        case .sameParty: return "Going to same party"
        case .sameConnectionMode: return "Same connection mode"
        }
    }
}

public struct MatchScore: Hashable {
    public let total: Int
    public let interestScore: Int
    public let distanceScore: Int
    public let collegeScore: Int
    public let partyScore: Int
    public let commonInterests: [String]
    public let reasons: [MatchReason]
    public let approximateDistanceKilometers: Double?
    public let sharedPartyName: String?

    public var displayText: String { "\(total)% Match" }
    public var nearbyDisplayText: String { "\(total)% Nearby Match" }

    public var samePartyBanner: String? {
        guard let sharedPartyName, !sharedPartyName.isEmpty else { return nil }
        return "You're both going to \(sharedPartyName) 🎉"
    }

    public var transparentBreakdown: String {
        "Interests 50% · Distance 20% · Same College 15% · Same Party 15%"
    }

    public var whyRecommended: String {
        if let banner = samePartyBanner {
            return banner
        }
        var highlights: [String] = []
        if !commonInterests.isEmpty {
            highlights.append("Common interests: \(commonInterests.prefix(3).joined(separator: ", "))")
        }
        if let km = approximateDistanceKilometers, km <= MatchEngine.nearbyThresholdKilometers {
            highlights.append("Within \(String(format: "%.1f km", km))")
        }
        if collegeScore > 0 {
            highlights.append("Same college")
        }
        return highlights.isEmpty ? "High overall compatibility" : highlights.joined(separator: " · ")
    }

    public init(
        total: Int,
        interestScore: Int,
        distanceScore: Int,
        collegeScore: Int,
        partyScore: Int,
        commonInterests: [String],
        reasons: [MatchReason],
        approximateDistanceKilometers: Double?,
        sharedPartyName: String?
    ) {
        self.total = max(0, min(100, total))
        self.interestScore = interestScore
        self.distanceScore = distanceScore
        self.collegeScore = collegeScore
        self.partyScore = partyScore
        self.commonInterests = commonInterests
        self.reasons = reasons
        self.approximateDistanceKilometers = approximateDistanceKilometers
        self.sharedPartyName = sharedPartyName
    }
}

public struct MatchCandidate {
    public let interests: [String]
    public let collegeName: String?
    public let approximateLatitude: Double?
    public let approximateLongitude: Double?
    public let attendingPartyIDs: Set<String>
    public let attendingPartyNames: [String: String]
    public let connectionMode: ConnectionMode?

    public init(
        interests: [String],
        collegeName: String?,
        approximateLatitude: Double?,
        approximateLongitude: Double?,
        attendingPartyIDs: Set<String>,
        attendingPartyNames: [String: String] = [:],
        connectionMode: ConnectionMode? = nil
    ) {
        self.interests = interests
        self.collegeName = collegeName
        self.approximateLatitude = approximateLatitude
        self.approximateLongitude = approximateLongitude
        self.attendingPartyIDs = attendingPartyIDs
        self.attendingPartyNames = attendingPartyNames
        self.connectionMode = connectionMode
    }
}

public struct MatchEngine {
    public static let interestWeight = 0.50
    public static let distanceWeight = 0.20
    public static let collegeWeight = 0.15
    public static let partyWeight = 0.15
    public static let nearbyThresholdKilometers = 5.0
    public static let maxDistanceKilometers = 25.0

    public static func score(user: MatchCandidate, candidate: MatchCandidate) -> MatchScore {
        let interestCompatibility = SmartMatchingEngine.calculateCompatibility(
            userInterests: user.interests,
            candidateInterests: candidate.interests
        )
        let interestComponent = Double(interestCompatibility.score)

        let distanceKm = LocationPrivacy.approximateDistanceKilometers(
            fromLatitude: user.approximateLatitude,
            fromLongitude: user.approximateLongitude,
            toLatitude: candidate.approximateLatitude,
            toLongitude: candidate.approximateLongitude
        )
        let distanceComponent = distanceScore(kilometers: distanceKm)

        let sameCollege = collegesMatch(user.collegeName, candidate.collegeName)
        let collegeComponent = sameCollege ? 100.0 : 0.0

        let sharedParties = user.attendingPartyIDs.intersection(candidate.attendingPartyIDs)
        let sameParty = !sharedParties.isEmpty
        let partyComponent = sameParty ? 100.0 : 0.0
        let sharedPartyName = sharedParties.compactMap { candidate.attendingPartyNames[$0] ?? user.attendingPartyNames[$0] }.first

        var available: [(Double, Double)] = [(interestWeight, interestComponent)]
        if distanceKm != nil {
            available.append((distanceWeight, distanceComponent))
        }
        available.append((collegeWeight, collegeComponent))
        available.append((partyWeight, partyComponent))

        let weightSum = available.reduce(0) { $0 + $1.0 }
        let weighted = available.reduce(0.0) { $0 + ($1.0 / weightSum) * $1.1 }
        let total = Int(weighted.rounded())

        var reasons: [MatchReason] = []
        if !interestCompatibility.commonInterests.isEmpty {
            reasons.append(.commonInterests)
        }
        if let distanceKm, distanceKm <= nearbyThresholdKilometers {
            reasons.append(.nearby)
        }
        if sameCollege {
            reasons.append(.sameCollege)
        }
        if sameParty {
            reasons.append(.sameParty)
        }
        if let uMode = user.connectionMode, let cMode = candidate.connectionMode,
           uMode == cMode || uMode == .both || cMode == .both {
            reasons.append(.sameConnectionMode)
        }

        return MatchScore(
            total: total,
            interestScore: Int(interestComponent.rounded()),
            distanceScore: Int(distanceComponent.rounded()),
            collegeScore: Int(collegeComponent.rounded()),
            partyScore: Int(partyComponent.rounded()),
            commonInterests: interestCompatibility.commonInterests,
            reasons: reasons,
            approximateDistanceKilometers: distanceKm,
            sharedPartyName: sharedPartyName
        )
    }

    public static func distanceScore(kilometers: Double?) -> Double {
        guard let kilometers else { return 0 }
        if kilometers <= 1 { return 100 }
        if kilometers >= maxDistanceKilometers { return 0 }
        let remaining = maxDistanceKilometers - kilometers
        return (remaining / (maxDistanceKilometers - 1)) * 100.0
    }

    public static func collegesMatch(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs, let rhs else { return false }
        let a = normalizeCollege(lhs)
        let b = normalizeCollege(rhs)
        return !a.isEmpty && a == b
    }

    public static func normalizeCollege(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
