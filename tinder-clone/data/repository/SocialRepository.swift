import Foundation
import UIKit
import CoreLocation

class SocialRepository {
    static let shared = SocialRepository()
    private let social = FirestoreSocialDataSource.shared
    private let firestore = FirestoreRemoteDataSource.shared
    private let storage = StorageRemoteDataSource.shared
    private let cards = ProfileCardRepository.shared
    private init() {}

    func createParty(
        name: String,
        description: String,
        date: Date,
        category: PartyCategory,
        maxParticipants: Int,
        approximateLocation: String,
        visibility: PartyVisibility,
        isEvent: Bool,
        privateLocation: String?,
        coordinate: CLLocationCoordinate2D?
    ) async throws -> String {
        var approxLat: Double?
        var approxLng: Double?
        var geohash: String?
        if let coordinate {
            let coarse = LocationPrivacy.coarsen(coordinate: coordinate)
            approxLat = coarse.latitude
            approxLng = coarse.longitude
            geohash = LocationPrivacy.geohash(for: coarse)
        }
        let current = try await firestore.getUserProfile(userId: try firestore.getUserId())
        let party = FirestoreParty(
            name: name,
            description: description,
            date: date,
            category: category.rawValue,
            maxParticipants: maxParticipants,
            approximateLocation: approximateLocation,
            approxLatitude: approxLat,
            approxLongitude: approxLng,
            geohash: geohash,
            visibility: visibility.rawValue,
            hostID: try firestore.getUserId(),
            hostName: current.name,
            participantCount: 0,
            college: current.college,
            imageURL: nil,
            isEvent: isEvent,
            createdAt: Date(),
            groupID: nil
        )
        return try await social.createParty(party, privateLocation: privateLocation)
    }

    func parties(isEvent: Bool?) async throws -> [FirestoreParty] {
        let blocked = try await social.blockedUserIds()
        return try await social.fetchParties(isEvent: isEvent).filter { !blocked.contains($0.hostID) }
    }

    func party(id: String) async throws -> FirestoreParty {
        try await social.fetchParty(id: id)
    }

    func privateLocation(partyID: String) async throws -> String? {
        try await social.fetchPrivateLocation(partyID: partyID)
    }

    func join(party: FirestoreParty) async throws {
        try await social.joinParty(partyID: party.id ?? "", partyName: party.name)
    }

    func leave(partyID: String) async throws {
        try await social.leaveParty(partyID: partyID)
    }

    func isMember(partyID: String) async throws -> Bool {
        try await social.isParticipant(partyID: partyID)
    }

    func invite(partyID: String, receiverID: String) async throws {
        try await social.inviteToParty(partyID: partyID, receiverID: receiverID)
    }

    func invitations() async throws -> [FirestorePartyInvitation] {
        try await social.fetchInvitations()
    }

    func respond(invitation: FirestorePartyInvitation, accept: Bool) async throws {
        guard let id = invitation.id else { return }
        try await social.respondToInvitation(id: id, accept: accept, partyID: invitation.partyID, partyName: invitation.partyName ?? "")
    }

    func nearbyPeople(radiusKm: Double, currentCoordinate: CLLocationCoordinate2D) async throws -> [ProfileCardModel] {
        let userId = try firestore.getUserId()
        let currentUser = try await firestore.getUserProfile(userId: userId)
        guard currentUser.nearbyEnabled == true else { return [] }
        let blocked = Array(try await social.blockedUserIds())
        let coarse = LocationPrivacy.coarsen(coordinate: currentCoordinate)
        let hash = LocationPrivacy.geohash(for: coarse)
        let prefixes = LocationPrivacy.neighborPrefixes(for: String(hash.prefix(4)))
        let users = try await social.fetchNearbyEnabledUsers(excluding: currentUser.liked + currentUser.passed + blocked, geohashPrefixes: prefixes)
        let mapped = try await cards.mapUsers(currentUser: currentUser, users: users)
        return mapped.filter { card in
            guard let km = card.matchScore?.approximateDistanceKilometers else { return false }
            return km <= radiusKm
        }.sorted { ($0.compatibilityScore ?? 0) > ($1.compatibilityScore ?? 0) }
    }

    func nearbyParties(radiusKm: Double, currentCoordinate: CLLocationCoordinate2D) async throws -> [FirestoreParty] {
        let parties = try await parties(isEvent: nil)
        return parties.filter { party in
            if party.partyVisibility == .inviteOnly { return false }
            guard let lat = party.approxLatitude, let lng = party.approxLongitude else { return false }
            let km = LocationPrivacy.approximateDistanceKilometers(
                fromLatitude: currentCoordinate.latitude,
                fromLongitude: currentCoordinate.longitude,
                toLatitude: lat,
                toLongitude: lng
            ) ?? 999
            return km <= radiusKm
        }
    }

    func participants(partyID: String) async throws -> [PartyParticipantPreview] {
        let ids = try await social.participantIds(partyID: partyID)
        let blocked = try await social.blockedUserIds()
        let me = try firestore.getUserId()
        let current = try await firestore.getUserProfile(userId: me)
        let currentParties = try await social.attendingPartyIDs(for: me)
        var previews: [PartyParticipantPreview] = []
        for id in ids.prefix(40) where id != me && !blocked.contains(id) {
            let user = try await firestore.getUserProfile(userId: id)
            let picture: UIImage?
            if let file = user.pictures.first {
                picture = try? await storage.getPicturesFromUser(userId: id, fileNames: [file]).first
            } else {
                picture = nil
            }
            let candidateParties = try await social.attendingPartyIDs(for: id)
            let score = MatchEngine.score(
                user: MatchCandidate(
                    interests: current.interests ?? [],
                    collegeName: current.college,
                    approximateLatitude: current.approxLatitude,
                    approximateLongitude: current.approxLongitude,
                    attendingPartyIDs: currentParties.ids,
                    attendingPartyNames: currentParties.names,
                    connectionMode: current.connectionMode
                ),
                candidate: MatchCandidate(
                    interests: user.interests ?? [],
                    collegeName: user.college,
                    approximateLatitude: user.approxLatitude,
                    approximateLongitude: user.approxLongitude,
                    attendingPartyIDs: candidateParties.ids,
                    attendingPartyNames: candidateParties.names,
                    connectionMode: user.connectionMode
                )
            )
            previews.append(PartyParticipantPreview(
                id: id,
                name: user.name,
                college: user.college,
                picture: picture,
                score: score,
                commonInterests: score.commonInterests
            ))
        }
        return previews
    }

    func sendPartyMessage(partyID: String, text: String, type: SocialMessageType = .text) throws {
        try social.sendPartyMessage(partyID: partyID, text: text, type: type)
    }

    func partyMessages(partyID: String) -> AsyncThrowingStream<[MessageModel], Error> {
        social.partyMessagesListener(partyID: partyID)
    }

    func block(userId: String) async throws {
        try await social.blockUser(userId: userId)
    }

    func unblock(userId: String) async throws {
        try await social.unblockUser(userId: userId)
    }

    func report(userId: String, reason: ReportReason, details: String) async throws {
        try await social.reportUser(userId: userId, reason: reason, details: details)
    }

    func unmatch(matchId: String) async throws {
        try await social.unmatch(matchId: matchId)
    }

    func blockedIds() async throws -> Set<String> {
        try await social.blockedUserIds()
    }

    func updateLocation(coordinate: CLLocationCoordinate2D, nearbyEnabled: Bool) async throws {
        try await social.updateApproximateLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            nearbyEnabled: nearbyEnabled
        )
    }

    func setNearbyEnabled(_ enabled: Bool) async throws {
        if enabled {
            let coordinate = try await LocationService.shared.requestOneShotLocation()
            try await updateLocation(coordinate: coordinate, nearbyEnabled: true)
        } else {
            try await social.updateApproximateLocation(
                latitude: 0,
                longitude: 0,
                nearbyEnabled: false
            )
            LocationService.shared.stopUpdates()
        }
    }

    func myParties() async throws -> [FirestoreParty] {
        let me = try firestore.getUserId()
        let attending = try await social.attendingPartyIDs(for: me)
        var result: [FirestoreParty] = []
        for id in attending.ids.prefix(30) {
            if let party = try? await social.fetchParty(id: id) {
                result.append(party)
            }
        }
        return result.sorted { $0.date < $1.date }
    }

    func matchesForInvite() async throws -> [MatchModel] {
        try await MatchRepository.shared.getMatches()
    }
}
