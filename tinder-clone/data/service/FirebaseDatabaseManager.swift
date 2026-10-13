//
//  FirebaseDatabaseManager.swift
//  AntiSocial
//
//  Created for Firebase Database connectivity verification & collection seeding.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
public class FirebaseDatabaseManager: ObservableObject {
    public static let shared = FirebaseDatabaseManager()

    @Published public var isConnected: Bool = false
    @Published public var connectionStatus: String = "Not initialized"
    @Published public var lastPingDurationMs: Double = 0
    @Published public var lastChecked: Date? = nil
    @Published public var isChecking: Bool = false
    @Published public var isSeeding: Bool = false
    @Published public var collectionCounts: [String: Int] = [:]
    @Published public var logMessages: [String] = []

    private init() {}

    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logLine = "[\(timestamp)] \(message)"
        logMessages.append(logLine)
        print(logLine)
    }

    /// Verifies connectivity to Cloud Firestore
    @discardableResult
    public func checkDatabaseConnection() async -> Bool {
        isChecking = true
        defer { isChecking = false }

        // 1. Check if FirebaseApp was configured
        guard FirebaseApp.allApps?.isEmpty == false else {
            self.isConnected = false
            self.connectionStatus = "FirebaseApp not configured. Please add GoogleService-Info.plist."
            log("❌ [Firebase] No configured FirebaseApp detected. Add GoogleService-Info.plist to target.")
            return false
        }

        log("🔍 [Firebase] Testing Cloud Firestore database connection...")
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            let db = Firestore.firestore()
            
            // 2. Perform write & read ping test in `_healthCheck` collection
            let pingDocRef = db.collection("_healthCheck").document("connection_status")
            try await pingDocRef.setData([
                "status": "online",
                "timestamp": FieldValue.serverTimestamp(),
                "client": "AntiSocial iOS",
                "platform": "SwiftUI"
            ], merge: true)

            let snapshot = try await pingDocRef.getDocument()
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

            if snapshot.exists {
                self.isConnected = true
                self.lastPingDurationMs = duration
                self.lastChecked = Date()
                self.connectionStatus = String(format: "Connected to Firestore (%.0f ms)", duration)
                log(String(format: "✅ [Firebase] Database connected successfully! Latency: %.0f ms", duration))

                // 3. Update collection counts
                await refreshCollectionCounts()
                return true
            } else {
                self.isConnected = false
                self.connectionStatus = "Database read returned empty document."
                log("⚠️ [Firebase] Health check document not found after write.")
                return false
            }
        } catch {
            self.isConnected = false
            self.connectionStatus = "Connection error: \(error.localizedDescription)"
            log("❌ [Firebase] Firestore connection check failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Fetches document counts for primary app collections
    public func refreshCollectionCounts() async {
        guard FirebaseApp.allApps?.isEmpty == false else { return }
        let db = Firestore.firestore()
        let collections = ["users", "parties", "events", "matches", "userLocations", "partyInvitations", "reports"]

        var newCounts: [String: Int] = [:]
        for colName in collections {
            do {
                let snap = try await db.collection(colName).limit(to: 50).getDocuments()
                newCounts[colName] = snap.documents.count
            } catch {
                newCounts[colName] = 0
            }
        }
        self.collectionCounts = newCounts
    }

    /// Seeds standard collections with rich AntiSocial application data
    public func seedInitialCollections() async {
        guard FirebaseApp.allApps?.isEmpty == false else {
            log("❌ [Firebase] Cannot seed: FirebaseApp is not configured.")
            return
        }

        isSeeding = true
        defer { isSeeding = false }

        let db = Firestore.firestore()
        log("🚀 [Firebase] Starting collection seeding with sample application data...")

        do {
            // ─── 1. Seed `users` Collection ─────────────────────────────────────────
            let calendar = Calendar.current
            let now = Date()

            // User 1: Ashwin (Both modes)
            let ashwinBirth = calendar.date(byAdding: .year, value: -22, to: now) ?? now
            try await db.collection("users").document("seed_user_ashwin").setData([
                "id": "seed_user_ashwin",
                "name": "Ashwin Baitade",
                "birthDate": Timestamp(date: ashwinBirth),
                "bio": "iOS Developer & AI engineer. Love hackathons, weekend music festivals, and campus meetups! 💻🎧",
                "male": true,
                "orientation": "women",
                "pictures": ["default-profile-picture", "elon_musk"],
                "liked": ["seed_user_sophia"],
                "passed": [] as [String],
                "connection_mode": "both",
                "college": "Stanford University",
                "interests": ["Tech & Startups", "House Parties", "Live Music", "Gaming"],
                "college_verified": true,
                "nearby_enabled": true,
                "show_approximate_distance": true,
                "allow_party_invitations": true,
                "allow_match_requests": true,
                "approx_latitude": 37.4275,
                "approx_longitude": -122.1697,
                "geohash": "9q9hv1",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ])

            // User 2: Sophia (Friends mode)
            let sophiaBirth = calendar.date(byAdding: .year, value: -21, to: now) ?? now
            try await db.collection("users").document("seed_user_sophia").setData([
                "id": "seed_user_sophia",
                "name": "Sophia Chen",
                "birthDate": Timestamp(date: sophiaBirth),
                "bio": "Product Design senior. Exploring coffee spots, architecture photography, and local gallery walks ☕️🎨",
                "male": false,
                "orientation": "men",
                "pictures": ["default-profile-picture"],
                "liked": ["seed_user_ashwin"],
                "passed": [] as [String],
                "connection_mode": "friends",
                "college": "UC Berkeley",
                "interests": ["Design & Art", "Coffee & Cafes", "Live Music", "Study Groups"],
                "college_verified": true,
                "nearby_enabled": true,
                "show_approximate_distance": true,
                "allow_party_invitations": true,
                "allow_match_requests": true,
                "approx_latitude": 37.8719,
                "approx_longitude": -122.2585,
                "geohash": "9q9p3x",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ])

            // User 3: Marcus (Party mode)
            let marcusBirth = calendar.date(byAdding: .year, value: -23, to: now) ?? now
            try await db.collection("users").document("seed_user_marcus").setData([
                "id": "seed_user_marcus",
                "name": "Marcus Brody",
                "birthDate": Timestamp(date: marcusBirth),
                "bio": "Music Producer & DJ. Organizing weekend rooftop sets and campus nightlife events 🪩✨",
                "male": true,
                "orientation": "both",
                "pictures": ["jeff_bezos"],
                "liked": [] as [String],
                "passed": [] as [String],
                "connection_mode": "party",
                "college": "Stanford University",
                "interests": ["Nightlife & Clubs", "House Parties", "DJing", "Festivals"],
                "college_verified": true,
                "nearby_enabled": true,
                "show_approximate_distance": true,
                "allow_party_invitations": true,
                "allow_match_requests": true,
                "approx_latitude": 37.4241,
                "approx_longitude": -122.1660,
                "geohash": "9q9hv0",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ])
            log("  ✓ Seeded 3 users in 'users' collection")

            // ─── 2. Seed `userLocations` Collection ─────────────────────────────────
            try await db.collection("userLocations").document("seed_user_ashwin").setData([
                "userId": "seed_user_ashwin",
                "approxLatitude": 37.4275,
                "approxLongitude": -122.1697,
                "geohash": "9q9hv1",
                "nearbyEnabled": true,
                "updatedAt": FieldValue.serverTimestamp()
            ])
            try await db.collection("userLocations").document("seed_user_sophia").setData([
                "userId": "seed_user_sophia",
                "approxLatitude": 37.8719,
                "approxLongitude": -122.2585,
                "geohash": "9q9p3x",
                "nearbyEnabled": true,
                "updatedAt": FieldValue.serverTimestamp()
            ])
            try await db.collection("userLocations").document("seed_user_marcus").setData([
                "userId": "seed_user_marcus",
                "approxLatitude": 37.4241,
                "approxLongitude": -122.1660,
                "geohash": "9q9hv0",
                "nearbyEnabled": true,
                "updatedAt": FieldValue.serverTimestamp()
            ])
            log("  ✓ Seeded locations in 'userLocations' collection")

            // ─── 3. Seed `parties` and `events` Collections ────────────────────────
            let upcomingDate1 = calendar.date(byAdding: .day, value: 3, to: now) ?? now
            let upcomingDate2 = calendar.date(byAdding: .day, value: 5, to: now) ?? now

            let party1Data: [String: Any] = [
                "name": "Silicon Campus Hackathon Afterparty",
                "description": "Celebrate the end of demo day! Food trucks, board games, DJ set & chill terrace.",
                "date": Timestamp(date: upcomingDate1),
                "category": "college_party",
                "maxParticipants": 100,
                "participantCount": 38,
                "approximateLocation": "Stanford Campus Student Center",
                "approxLatitude": 37.4282,
                "approxLongitude": -122.1688,
                "geohash": "9q9hv1",
                "visibility": "public",
                "hostID": "seed_user_ashwin",
                "hostName": "Ashwin Baitade",
                "college": "Stanford University",
                "isEvent": false,
                "createdAt": FieldValue.serverTimestamp()
            ]
            try await db.collection("parties").document("seed_party_hackathon").setData(party1Data)

            let event1Data: [String: Any] = [
                "name": "Neon Lights & EDM Night",
                "description": "Live DJ sets featuring campus talent. Glowsticks and neon accessories provided!",
                "date": Timestamp(date: upcomingDate2),
                "category": "music",
                "maxParticipants": 150,
                "participantCount": 62,
                "approximateLocation": "Downtown Berkeley Stage",
                "approxLatitude": 37.8700,
                "approxLongitude": -122.2680,
                "geohash": "9q9p3x",
                "visibility": "public",
                "hostID": "seed_user_marcus",
                "hostName": "Marcus Brody",
                "college": "Stanford University",
                "isEvent": true,
                "createdAt": FieldValue.serverTimestamp()
            ]
            try await db.collection("parties").document("seed_party_neon_night").setData(event1Data)
            try await db.collection("events").document("seed_party_neon_night").setData(event1Data)
            log("  ✓ Seeded parties & events in 'parties' and 'events' collections")

            // ─── 4. Seed `matches` Collection & Messages ───────────────────────────
            let matchDocRef = db.collection("matches").document("seed_match_ashwin_sophia")
            try await matchDocRef.setData([
                "usersMatched": ["seed_user_ashwin", "seed_user_sophia"],
                "timestamp": FieldValue.serverTimestamp(),
                "status": "active"
            ])

            try await matchDocRef.collection("messages").addDocument(data: [
                "message": "Hey Sophia! Saw your interest in live music — are you checking out the EDM night this Friday?",
                "timestamp": FieldValue.serverTimestamp(),
                "senderId": "seed_user_ashwin",
                "type": "text"
            ])
            log("  ✓ Seeded mutual match and conversation in 'matches' collection")

            // ─── 5. Seed `partyInvitations` Collection ──────────────────────────────
            try await db.collection("partyInvitations").document("seed_invite_marcus_ashwin").setData([
                "partyID": "seed_party_neon_night",
                "partyName": "Neon Lights & EDM Night",
                "partyDate": Timestamp(date: upcomingDate2),
                "senderID": "seed_user_marcus",
                "senderName": "Marcus Brody",
                "receiverID": "seed_user_ashwin",
                "status": "pending",
                "createdAt": FieldValue.serverTimestamp()
            ])
            log("  ✓ Seeded invitations in 'partyInvitations' collection")

            // Refresh collection counters
            await refreshCollectionCounts()
            log("🎉 [Firebase] Successfully seeded all collections!")
        } catch {
            log("❌ [Firebase] Failed to seed collections: \(error.localizedDescription)")
        }
    }
}
