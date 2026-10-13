//
//  SocialModels.swift
//  AntiSocial
//

import Foundation
import UIKit
import FirebaseFirestoreSwift

enum PartyVisibility: String, Codable, CaseIterable, Identifiable {
    case `public` = "public"
    case matches = "matches"
    case inviteOnly = "invite_only"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .public: return "Public"
        case .matches: return "Matches/Friends"
        case .inviteOnly: return "Invite Only"
        }
    }
}

enum PartyCategory: String, Codable, CaseIterable, Identifiable {
    case collegeParty = "college_party"
    case music
    case gaming
    case sports
    case food
    case movie
    case meetup
    case festival
    case workshop
    case other
    case dance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .collegeParty: return "College Party"
        case .music: return "Music"
        case .gaming: return "Gaming"
        case .sports: return "Sports"
        case .food: return "Food"
        case .movie: return "Movie"
        case .meetup: return "Meetup"
        case .festival: return "Festival"
        case .workshop: return "Workshop"
        case .other: return "Other"
        case .dance: return "Dance"
        }
    }
}

enum InvitationStatus: String, Codable {
    case pending, accepted, declined, cancelled
}

enum MatchStatus: String, Codable {
    case active, unmatched, blocked
}

enum SocialMessageType: String, Codable {
    case text
    case system
    case game
    case aiIcebreaker = "AI_icebreaker"
}

enum ReportReason: String, Codable, CaseIterable, Identifiable {
    case spam
    case harassment
    case fakeProfile = "fake_profile"
    case inappropriateContent = "inappropriate_content"
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spam: return "Spam"
        case .harassment: return "Harassment"
        case .fakeProfile: return "Fake Profile"
        case .inappropriateContent: return "Inappropriate Content"
        case .other: return "Other"
        }
    }
}

struct FirestoreParty: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var date: Date
    var category: String
    var maxParticipants: Int
    var approximateLocation: String
    var approxLatitude: Double?
    var approxLongitude: Double?
    var geohash: String?
    var visibility: String
    var hostID: String
    var hostName: String?
    var participantCount: Int
    var college: String?
    var imageURL: String?
    var isEvent: Bool
    var createdAt: Date?
    var groupID: String?

    var partyCategory: PartyCategory {
        PartyCategory(rawValue: category) ?? .other
    }

    var partyVisibility: PartyVisibility {
        PartyVisibility(rawValue: visibility) ?? .public
    }
}

public struct FirestorePartyInvitation: Codable, Identifiable, Equatable {
    @DocumentID public var id: String?
    public var partyID: String
    public var senderID: String
    public var receiverID: String
    public var status: String
    public var createdAt: Date?
    public var partyName: String?
    public var senderName: String?
    public var partyDate: Date?
    public var approxLatitude: Double?
    public var approxLongitude: Double?

    public init(
        id: String? = nil,
        partyID: String,
        senderID: String,
        receiverID: String,
        status: String = InvitationStatus.pending.rawValue,
        createdAt: Date? = nil,
        partyName: String? = nil,
        senderName: String? = nil,
        partyDate: Date? = nil,
        approxLatitude: Double? = nil,
        approxLongitude: Double? = nil
    ) {
        self.id = id
        self.partyID = partyID
        self.senderID = senderID
        self.receiverID = receiverID
        self.status = status
        self.createdAt = createdAt
        self.partyName = partyName
        self.senderName = senderName
        self.partyDate = partyDate
        self.approxLatitude = approxLatitude
        self.approxLongitude = approxLongitude
    }
}

public typealias PartyInvitation = FirestorePartyInvitation

public struct FirestoreUserLocation: Codable, Identifiable, Equatable {
    @DocumentID public var id: String?
    public var userId: String
    public var approxLatitude: Double?
    public var approxLongitude: Double?
    public var geohash: String?
    public var nearbyEnabled: Bool
    public var updatedAt: Date?

    public init(
        id: String? = nil,
        userId: String,
        approxLatitude: Double? = nil,
        approxLongitude: Double? = nil,
        geohash: String? = nil,
        nearbyEnabled: Bool = false,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.approxLatitude = approxLatitude
        self.approxLongitude = approxLongitude
        self.geohash = geohash
        self.nearbyEnabled = nearbyEnabled
        self.updatedAt = updatedAt
    }
}

public struct FirestoreReport: Codable {
    public var reporterID: String
    public var reportedUserID: String
    public var reason: String
    public var details: String
    public var createdAt: Date?

    public init(
        reporterID: String,
        reportedUserID: String,
        reason: String,
        details: String,
        createdAt: Date? = nil
    ) {
        self.reporterID = reporterID
        self.reportedUserID = reportedUserID
        self.reason = reason
        self.details = details
        self.createdAt = createdAt
    }
}

public struct PartyParticipantPreview: Identifiable {
    public let id: String
    public let name: String
    public let college: String?
    public let picture: UIImage?
    public let score: MatchScore?
    public let commonInterests: [String]

    public init(
        id: String,
        name: String,
        college: String?,
        picture: UIImage?,
        score: MatchScore?,
        commonInterests: [String]
    ) {
        self.id = id
        self.name = name
        self.college = college
        self.picture = picture
        self.score = score
        self.commonInterests = commonInterests
    }
}
