//
//  FirestoreUser.swift
//  AntiSocial
//

import Foundation
import FirebaseFirestore
#if canImport(FirebaseFirestoreSwift)
import FirebaseFirestoreSwift
#endif

public enum ConnectionMode: String, Codable, CaseIterable {
    case friends = "friends"
    case party = "party"
    case both = "both"

    public var titleKey: String {
        switch self {
        case .friends: return "friend-mode"
        case .party: return "party-mode"
        case .both: return "both-modes"
        }
    }

    public var badgeKey: String {
        switch self {
        case .friends: return "friend-mode-badge"
        case .party: return "party-mode-badge"
        case .both: return "both-modes-badge"
        }
    }
}

public struct FirestoreUser: Codable, Equatable {
    @DocumentID var id: String?
    let name: String
    let birthDate: Date
    let bio: String
    let isMale: Bool
    let orientation: Orientation
    let pictures: [String]
    let liked: [String]
    let passed: [String]
    let connectionMode: ConnectionMode?
    let college: String?
    let interests: [String]?
    let collegeEmail: String?
    let collegeVerified: Bool?
    let nearbyEnabled: Bool?
    let showApproximateDistance: Bool?
    let allowPartyInvitations: Bool?
    let allowMatchRequests: Bool?
    let approxLatitude: Double?
    let approxLongitude: Double?
    let geohash: String?
    let createdAt: Date?
    let updatedAt: Date?

    var age: Int {
        Date().years(from: birthDate)
    }

    var profileImagePath: String? {
        pictures.first
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case birthDate
        case bio
        case isMale = "male"
        case orientation
        case pictures
        case liked
        case passed
        case connectionMode = "connection_mode"
        case college
        case interests
        case collegeEmail = "college_email"
        case collegeVerified = "college_verified"
        case nearbyEnabled = "nearby_enabled"
        case showApproximateDistance = "show_approximate_distance"
        case allowPartyInvitations = "allow_party_invitations"
        case allowMatchRequests = "allow_match_requests"
        case approxLatitude = "approx_latitude"
        case approxLongitude = "approx_longitude"
        case geohash
        case createdAt
        case updatedAt
    }

    public init(
        id: String? = nil,
        name: String,
        birthDate: Date,
        bio: String,
        isMale: Bool,
        orientation: Orientation,
        pictures: [String],
        liked: [String],
        passed: [String],
        connectionMode: ConnectionMode? = .both,
        college: String? = nil,
        interests: [String]? = [],
        collegeEmail: String? = nil,
        collegeVerified: Bool? = false,
        nearbyEnabled: Bool? = false,
        showApproximateDistance: Bool? = true,
        allowPartyInvitations: Bool? = true,
        allowMatchRequests: Bool? = true,
        approxLatitude: Double? = nil,
        approxLongitude: Double? = nil,
        geohash: String? = nil,
        createdAt: Date? = Date(),
        updatedAt: Date? = Date()
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.bio = bio
        self.isMale = isMale
        self.orientation = orientation
        self.pictures = pictures
        self.liked = liked
        self.passed = passed
        self.connectionMode = connectionMode
        self.college = college
        self.interests = interests
        self.collegeEmail = collegeEmail
        self.collegeVerified = collegeVerified
        self.nearbyEnabled = nearbyEnabled
        self.showApproximateDistance = showApproximateDistance
        self.allowPartyInvitations = allowPartyInvitations
        self.allowMatchRequests = allowMatchRequests
        self.approxLatitude = approxLatitude
        self.approxLongitude = approxLongitude
        self.geohash = geohash
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum Orientation: String, Codable, CaseIterable {
    case men, women, both
}
