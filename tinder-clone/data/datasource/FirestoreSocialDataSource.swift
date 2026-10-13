//
//  FirestoreSocialDataSource.swift
//  AntiSocial
//

import Foundation
import CoreLocation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

class FirestoreSocialDataSource {
    static let shared = FirestoreSocialDataSource()
    private let db = Firestore.firestore()
    private init() {}

    private func userId() throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthErrorModel(message: "User not signed in.")
        }
        return userId
    }

    func blockedUserIds() async throws -> Set<String> {
        let snapshot = try await db.collection("users").document(try userId()).collection("blockedUsers").limit(to: 200).getDocuments()
        return Set(snapshot.documents.map { $0.documentID })
    }

    func blockUser(userId blockedId: String) async throws {
        let me = try userId()
        try await db.collection("users").document(me).collection("blockedUsers").document(blockedId).setData([
            "createdAt": FieldValue.serverTimestamp()
        ])
        let matchId = matchId(userId1: me, userId2: blockedId)
        try await db.collection("matches").document(matchId).setData([
            "status": MatchStatus.blocked.rawValue
        ], merge: true)
    }

    func unblockUser(userId blockedId: String) async throws {
        try await db.collection("users").document(try userId()).collection("blockedUsers").document(blockedId).delete()
    }

    func reportUser(userId reportedId: String, reason: ReportReason, details: String) async throws {
        let report = FirestoreReport(
            reporterID: try userId(),
            reportedUserID: reportedId,
            reason: reason.rawValue,
            details: details,
            createdAt: Date()
        )
        try db.collection("reports").addDocument(from: report)
    }

    func unmatch(matchId: String) async throws {
        try await db.collection("matches").document(matchId).setData([
            "status": MatchStatus.unmatched.rawValue
        ], merge: true)
    }

    func attendingPartyIDs(for userId: String) async throws -> (ids: Set<String>, names: [String: String]) {
        let snapshot = try await db.collection("partyParticipants")
            .whereField("userID", isEqualTo: userId)
            .limit(to: 30)
            .getDocuments()
        var ids = Set<String>()
        var names: [String: String] = [:]
        for document in snapshot.documents {
            if let partyID = document.data()["partyID"] as? String {
                ids.insert(partyID)
                if let name = document.data()["partyName"] as? String {
                    names[partyID] = name
                }
            }
        }
        return (ids, names)
    }

    func fetchNearbyEnabledUsers(excluding excluded: [String], geohashPrefixes: [String]) async throws -> [FirestoreUser] {
        let me = try userId()
        var collected: [FirestoreUser] = []
        let prefixes = Array(Set(geohashPrefixes)).prefix(9)
        for prefix in prefixes {
            let snapshot = try await db.collection("users")
                .whereField("nearby_enabled", isEqualTo: true)
                .whereField("geohash", isGreaterThanOrEqualTo: prefix)
                .whereField("geohash", isLessThan: prefix + "~")
                .limit(to: 25)
                .getDocuments()
            for document in snapshot.documents where document.documentID != me && !excluded.contains(document.documentID) {
                if let user = try? document.data(as: FirestoreUser.self) {
                    collected.append(user)
                }
            }
        }
        var unique: [String: FirestoreUser] = [:]
        for user in collected {
            if let id = user.id {
                unique[id] = user
            }
        }
        return Array(unique.values)
    }

    func createParty(_ party: FirestoreParty, privateLocation: String?) async throws -> String {
        let me = try userId()
        var data = party
        data.hostID = me
        data.participantCount = 1
        data.createdAt = Date()
        let ref = try db.collection("parties").addDocument(from: data)
        if party.isEvent {
            try? await db.collection("events").document(ref.documentID).setData(from: data)
        }
        try await joinParty(partyID: ref.documentID, partyName: party.name, isHost: true)
        if let privateLocation, !privateLocation.isEmpty {
            try await db.collection("parties").document(ref.documentID).collection("private").document("details").setData([
                "locationNote": privateLocation,
                "updatedAt": FieldValue.serverTimestamp()
            ])
            if party.isEvent {
                try? await db.collection("events").document(ref.documentID).collection("private").document("details").setData([
                    "locationNote": privateLocation,
                    "updatedAt": FieldValue.serverTimestamp()
                ])
            }
        }
        try await db.collection("partyGroups").document(ref.documentID).setData([
            "groupID": ref.documentID,
            "partyID": ref.documentID,
            "members": [me],
            "createdAt": FieldValue.serverTimestamp()
        ])
        return ref.documentID
    }

    func fetchParties(isEvent: Bool?, limit: Int = 40) async throws -> [FirestoreParty] {
        var query: Query = db.collection("parties").order(by: "date", descending: false).limit(to: limit)
        if let isEvent {
            query = db.collection("parties").whereField("isEvent", isEqualTo: isEvent).order(by: "date", descending: false).limit(to: limit)
        }
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: FirestoreParty.self) }
    }

    func fetchParty(id: String) async throws -> FirestoreParty {
        let snapshot = try await db.collection("parties").document(id).getDocument()
        guard let party = try snapshot.data(as: FirestoreParty.self) else {
            throw ParsingError(message: "Could not parse party.")
        }
        return party
    }

    func fetchPrivateLocation(partyID: String) async throws -> String? {
        let snapshot = try await db.collection("parties").document(partyID).collection("private").document("details").getDocument()
        return snapshot.data()?["locationNote"] as? String
    }

    func joinParty(partyID: String, partyName: String, isHost: Bool = false) async throws {
        let me = try userId()
        let participantId = "\(partyID)_\(me)"
        let existing = try await db.collection("partyParticipants").document(participantId).getDocument()
        if existing.exists { return }
        let participantData: [String: Any] = [
            "partyID": partyID,
            "userID": me,
            "partyName": partyName,
            "isHost": isHost,
            "createdAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("partyParticipants").document(participantId).setData(participantData)
        try? await db.collection("eventParticipants").document(participantId).setData(participantData)
        try await db.collection("parties").document(partyID).updateData([
            "participantCount": FieldValue.increment(Int64(1))
        ])
        try? await db.collection("events").document(partyID).updateData([
            "participantCount": FieldValue.increment(Int64(1))
        ])
        try await db.collection("partyGroups").document(partyID).setData([
            "members": FieldValue.arrayUnion([me])
        ], merge: true)
    }

    func leaveParty(partyID: String) async throws {
        let me = try userId()
        let participantId = "\(partyID)_\(me)"
        try await db.collection("partyParticipants").document(participantId).delete()
        try? await db.collection("eventParticipants").document(participantId).delete()
        try await db.collection("parties").document(partyID).updateData([
            "participantCount": FieldValue.increment(Int64(-1))
        ])
        try? await db.collection("events").document(partyID).updateData([
            "participantCount": FieldValue.increment(Int64(-1))
        ])
        try await db.collection("partyGroups").document(partyID).setData([
            "members": FieldValue.arrayRemove([me])
        ], merge: true)
    }

    func isParticipant(partyID: String, userID: String? = nil) async throws -> Bool {
        let uid = try userID ?? userId()
        let snapshot = try await db.collection("partyParticipants").document("\(partyID)_\(uid)").getDocument()
        return snapshot.exists
    }

    func participantIds(partyID: String) async throws -> [String] {
        let snapshot = try await db.collection("partyParticipants")
            .whereField("partyID", isEqualTo: partyID)
            .limit(to: 80)
            .getDocuments()
        return snapshot.documents.compactMap { $0.data()["userID"] as? String }
    }

    func inviteToParty(partyID: String, receiverID: String) async throws {
        let me = try userId()
        let existing = try await db.collection("partyInvitations")
            .whereField("partyID", isEqualTo: partyID)
            .whereField("senderID", isEqualTo: me)
            .whereField("receiverID", isEqualTo: receiverID)
            .limit(to: 5)
            .getDocuments()
        if existing.documents.contains(where: { ($0.data()["status"] as? String) == InvitationStatus.pending.rawValue }) {
            throw AuthErrorModel(message: "Invitation already sent.")
        }
        var partyName: String?
        var partyDate: Date?
        var approxLat: Double?
        var approxLng: Double?
        if let partyDoc = try? await db.collection("parties").document(partyID).getDocument(),
           let party = try? partyDoc.data(as: FirestoreParty.self) {
            partyName = party.name
            partyDate = party.date
            approxLat = party.approxLatitude
            approxLng = party.approxLongitude
        }
        var senderName: String?
        if let userDoc = try? await db.collection("users").document(me).getDocument(),
           let user = try? userDoc.data(as: FirestoreUser.self) {
            senderName = user.name
        }
        var inviteData: [String: Any] = [
            "partyID": partyID,
            "senderID": me,
            "receiverID": receiverID,
            "status": InvitationStatus.pending.rawValue,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let partyName { inviteData["partyName"] = partyName }
        if let senderName { inviteData["senderName"] = senderName }
        if let partyDate { inviteData["partyDate"] = partyDate }
        if let approxLat { inviteData["approxLatitude"] = approxLat }
        if let approxLng { inviteData["approxLongitude"] = approxLng }

        try await db.collection("partyInvitations").addDocument(data: inviteData)
        LocalNotificationRouter().handle(
            event: .partyInvitation,
            title: "Party Invitation Sent 🎉",
            body: "You invited a friend to \(partyName ?? "the party")"
        )
    }

    func fetchInvitations() async throws -> [FirestorePartyInvitation] {
        let snapshot = try await db.collection("partyInvitations")
            .whereField("receiverID", isEqualTo: try userId())
            .whereField("status", isEqualTo: InvitationStatus.pending.rawValue)
            .limit(to: 40)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: FirestorePartyInvitation.self) }
    }

    func respondToInvitation(id: String, accept: Bool, partyID: String, partyName: String) async throws {
        try await db.collection("partyInvitations").document(id).updateData([
            "status": (accept ? InvitationStatus.accepted : InvitationStatus.declined).rawValue
        ])
        if accept {
            try await joinParty(partyID: partyID, partyName: partyName)
            LocalNotificationRouter().handle(
                event: .invitationAccepted,
                title: "Party Invitation Accepted 🎉",
                body: "You're attending \(partyName.isEmpty ? "the party" : partyName)!"
            )
        }
    }

    func sendPartyMessage(partyID: String, text: String, type: SocialMessageType) throws {
        db.collection("partyGroups").document(partyID).collection("messages").addDocument(data: [
            "senderId": try userId(),
            "message": text,
            "timestamp": FieldValue.serverTimestamp(),
            "type": type.rawValue
        ])
    }

    func partyMessagesListener(partyID: String) -> AsyncThrowingStream<[MessageModel], Error> {
        AsyncThrowingStream { continuation in
            let registration = db.collection("partyGroups").document(partyID).collection("messages")
                .order(by: "timestamp", descending: false)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    let uid = (try? self.userId()) ?? ""
                    let messages: [MessageModel] = snapshot?.documents.compactMap { document in
                        guard let firestoreMessage = try? document.data(as: FirestoreMessage.self) else { return nil }
                        return MessageModel.from(id: document.documentID, firestoreMessage, currentUserId: uid)
                    } ?? []
                    continuation.yield(messages)
                }
            continuation.onTermination = { _ in
                registration.remove()
            }
        }
    }

    func updateApproximateLocation(latitude: Double, longitude: Double, nearbyEnabled: Bool) async throws {
        let uid = try userId()
        let coarse = LocationPrivacy.coarsen(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        var userData: [String: Any] = [
            "nearby_enabled": nearbyEnabled,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        var locationData: [String: Any] = [
            "userId": uid,
            "nearbyEnabled": nearbyEnabled,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if nearbyEnabled {
            userData["approx_latitude"] = coarse.latitude
            userData["approx_longitude"] = coarse.longitude
            userData["geohash"] = LocationPrivacy.geohash(for: coarse)

            locationData["approxLatitude"] = coarse.latitude
            locationData["approxLongitude"] = coarse.longitude
            locationData["geohash"] = LocationPrivacy.geohash(for: coarse)
        } else {
            userData["approx_latitude"] = FieldValue.delete()
            userData["approx_longitude"] = FieldValue.delete()
            userData["geohash"] = FieldValue.delete()

            locationData["approxLatitude"] = FieldValue.delete()
            locationData["approxLongitude"] = FieldValue.delete()
            locationData["geohash"] = FieldValue.delete()
        }
        try await db.collection("users").document(uid).updateData(userData)
        try await db.collection("userLocations").document(uid).setData(locationData, merge: true)
    }

    private func matchId(userId1: String, userId2: String) -> String {
        userId1 > userId2 ? userId1 + userId2 : userId2 + userId1
    }
}
