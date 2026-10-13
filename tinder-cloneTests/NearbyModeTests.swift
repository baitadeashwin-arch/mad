import XCTest
@testable import tinder_clone
import CoreLocation

final class NearbyModeTests: XCTestCase {

    override func setUpWithError() throws {
        // Setup code if needed
    }

    override func tearDownWithError() throws {
        // Teardown code if needed
    }

    func testLocationPrivacyCoarsening() throws {
        // Ensure coordinates are coarsened to prevent precise tracking
        let exactCoordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        let coarsened = LocationPrivacy.coarsen(coordinate: exactCoordinate)
        
        // Coarsening should truncate/round latitude and longitude to 2 or 3 decimal places
        // The difference should be greater than zero but less than ~2km equivalent
        XCTAssertNotEqual(exactCoordinate.latitude, coarsened.latitude)
        XCTAssertNotEqual(exactCoordinate.longitude, coarsened.longitude)
    }

    func testLocationPrivacyDistanceLabel() throws {
        let distanceText = LocationPrivacy.distanceLabel(kilometers: 1.2, collegeHint: "RIT")
        XCTAssertEqual(distanceText, "1.2 km away")
        
        let unknownDistanceText = LocationPrivacy.distanceLabel(kilometers: nil, collegeHint: "RIT")
        XCTAssertEqual(unknownDistanceText, "Near RIT")
        
        let fullyUnknownText = LocationPrivacy.distanceLabel(kilometers: nil, collegeHint: nil)
        XCTAssertEqual(fullyUnknownText, "Distance unavailable")
    }

    func testMatchEngineScoring() throws {
        let user = MatchCandidate(
            interests: ["gaming", "music", "movies"],
            collegeName: "RIT",
            approximateLatitude: 40.7,
            approximateLongitude: -74.0,
            attendingPartyIDs: ["party123"],
            attendingPartyNames: ["Freshers Party"],
            connectionMode: .both
        )
        
        let candidate = MatchCandidate(
            interests: ["music", "movies", "sports"],
            collegeName: "RIT",
            approximateLatitude: 40.71,
            approximateLongitude: -74.01,
            attendingPartyIDs: ["party123", "party456"],
            attendingPartyNames: ["Freshers Party", "Halloween Party"],
            connectionMode: .both
        )
        
        let score = MatchEngine.score(user: user, candidate: candidate)
        
        // Shared interests: music, movies
        // Same college: RIT
        // Same party: Freshers Party
        // Close distance
        
        XCTAssertGreaterThan(score.total, 0)
        XCTAssertEqual(score.commonInterests.count, 2)
        XCTAssertEqual(score.sharedPartyName, "Freshers Party")
        XCTAssertTrue(score.reasons.contains(where: { $0.title.contains("Both going to Freshers Party") }))
    }

    func testInvitationStateMachine() throws {
        let initialStatus = InvitationStatus.pending
        XCTAssertTrue(InvitationStateMachine.canRespond(initialStatus))
        
        let accepted = InvitationStateMachine.nextStatus(current: initialStatus, accept: true)
        XCTAssertEqual(accepted, .accepted)
        
        let declined = InvitationStateMachine.nextStatus(current: initialStatus, accept: false)
        XCTAssertEqual(declined, .declined)
        
        let duplicateCheck = InvitationStateMachine.isDuplicate(existing: [.declined, .pending])
        XCTAssertTrue(duplicateCheck)
        
        let noDuplicateCheck = InvitationStateMachine.isDuplicate(existing: [.declined, .accepted])
        XCTAssertFalse(noDuplicateCheck)
    }

    func testSafetyRulesBlockFilter() throws {
        let blockFilter = BlockFilter(blockedUserIDs: ["userA", "userC"])
        
        XCTAssertTrue(blockFilter.shouldHide(userID: "userA"))
        XCTAssertFalse(blockFilter.shouldHide(userID: "userB"))
        
        let testUsers = ["userA", "userB", "userC", "userD"]
        let visibleUsers = blockFilter.visible(testUsers, userID: { $0 })
        
        XCTAssertEqual(visibleUsers.count, 2)
        XCTAssertTrue(visibleUsers.contains("userB"))
        XCTAssertTrue(visibleUsers.contains("userD"))
    }
}
