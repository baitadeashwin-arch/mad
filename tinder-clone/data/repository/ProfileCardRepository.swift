import Foundation

class ProfileCardRepository {
    private init() {}
    static let shared = ProfileCardRepository()

    private let storageDataSource: StorageRemoteDataSource = StorageRemoteDataSource.shared
    private let firestoreDataSource: FirestoreRemoteDataSource = FirestoreRemoteDataSource.shared
    private let socialDataSource: FirestoreSocialDataSource = FirestoreSocialDataSource.shared

    func swipeUser(swipedUserId: String, hasLiked: Bool) async throws -> Bool {
        return try await firestoreDataSource.swipeUser(swipedUserId: swipedUserId, hasLiked: hasLiked)
    }

    func getProfiles() async throws -> [ProfileCardModel] {
        let userId = try firestoreDataSource.getUserId()
        let currentUser = try await firestoreDataSource.getUserProfile(userId: userId)
        let excludedUserIds = currentUser.liked + currentUser.passed
        let compatibleUsers = try await firestoreDataSource.getCompatibleUsers(
            isUserMale: currentUser.isMale,
            userOrientation: currentUser.orientation,
            excludedUsers: excludedUserIds
        )
        return try await mapUsers(currentUser: currentUser, users: compatibleUsers)
    }

    func mapUsers(currentUser: FirestoreUser, users: [FirestoreUser]) async throws -> [ProfileCardModel] {
        let usersMap = users.reduce(into: [String: [String]]()) {
            if let id = $1.id {
                $0[id] = $1.pictures
            }
        }
        let picturesMap = try await storageDataSource.getPicturesFromUsers(usersMap: usersMap)
        let currentParties = try await socialDataSource.attendingPartyIDs(for: try firestoreDataSource.getUserId())
        let currentCandidate = MatchCandidate(
            interests: currentUser.interests ?? [],
            collegeName: currentUser.college,
            approximateLatitude: currentUser.approxLatitude,
            approximateLongitude: currentUser.approxLongitude,
            attendingPartyIDs: currentParties.ids,
            attendingPartyNames: currentParties.names,
            connectionMode: currentUser.connectionMode
        )

        let userProfiles: [ProfileCardModel] = try await withThrowingTaskGroup(of: ProfileCardModel?.self) { group in
            for user in users {
                group.addTask {
                    guard let id = user.id, let pictures = picturesMap[id] else { return nil }
                    let candidateParties = try await self.socialDataSource.attendingPartyIDs(for: id)
                    let candidate = MatchCandidate(
                        interests: user.interests ?? [],
                        collegeName: user.college,
                        approximateLatitude: user.approxLatitude,
                        approximateLongitude: user.approxLongitude,
                        attendingPartyIDs: candidateParties.ids,
                        attendingPartyNames: candidateParties.names,
                        connectionMode: user.connectionMode
                    )
                    let score = MatchEngine.score(user: currentCandidate, candidate: candidate)
                    let showDistance = user.showApproximateDistance ?? true
                    let distanceText = showDistance ? LocationPrivacy.distanceLabel(
                        kilometers: score.approximateDistanceKilometers,
                        collegeHint: user.college
                    ) : nil
                    let starter = await AIService.shared.conversationStarter(
                        commonInterests: score.commonInterests,
                        sharedPartyName: score.sharedPartyName
                    )
                    return ProfileCardModel(
                        userId: id,
                        name: user.name,
                        age: user.age,
                        pictures: pictures,
                        bio: user.bio,
                        college: user.college,
                        collegeVerified: user.collegeVerified ?? false,
                        connectionMode: user.connectionMode,
                        interests: user.interests,
                        compatibilityScore: score.total,
                        commonInterests: score.commonInterests,
                        conversationStarter: starter,
                        matchScore: score,
                        approximateDistanceText: distanceText
                    )
                }
            }
            var collected: [ProfileCardModel] = []
            for try await item in group {
                if let item { collected.append(item) }
            }
            return collected
        }

        return userProfiles.sorted { ($0.compatibilityScore ?? 0) < ($1.compatibilityScore ?? 0) }
    }
}
