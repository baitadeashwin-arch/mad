import UIKit

struct ProfileCardModel: Identifiable {
    var id: String { userId }
    let userId: String
    let name: String
    let age: Int
    let pictures: [UIImage]
    let bio: String?
    let college: String?
    let collegeVerified: Bool
    let connectionMode: ConnectionMode?
    let interests: [String]?
    let compatibilityScore: Int?
    let commonInterests: [String]?
    let conversationStarter: String?
    let matchScore: MatchScore?
    let approximateDistanceText: String?

    init(
        userId: String,
        name: String,
        age: Int,
        pictures: [UIImage],
        bio: String? = nil,
        college: String? = nil,
        collegeVerified: Bool = false,
        connectionMode: ConnectionMode? = .both,
        interests: [String]? = [],
        compatibilityScore: Int? = nil,
        commonInterests: [String]? = [],
        conversationStarter: String? = nil,
        matchScore: MatchScore? = nil,
        approximateDistanceText: String? = nil
    ) {
        self.userId = userId
        self.name = name
        self.age = age
        self.pictures = pictures
        self.bio = bio
        self.college = college
        self.collegeVerified = collegeVerified
        self.connectionMode = connectionMode
        self.interests = interests
        self.compatibilityScore = compatibilityScore
        self.commonInterests = commonInterests
        self.conversationStarter = conversationStarter
        self.matchScore = matchScore
        self.approximateDistanceText = approximateDistanceText
    }
}
