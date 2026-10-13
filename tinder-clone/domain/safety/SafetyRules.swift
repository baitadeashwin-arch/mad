//
//  SafetyRules.swift
//  AntiSocial
//

import Foundation

public struct BlockFilter {
    public let blockedUserIDs: Set<String>

    public init(blockedUserIDs: Set<String>) {
        self.blockedUserIDs = blockedUserIDs
    }

    public func shouldHide(userID: String) -> Bool {
        blockedUserIDs.contains(userID)
    }

    public func visible<T>(_ items: [T], userID: (T) -> String) -> [T] {
        items.filter { !shouldHide(userID: userID($0)) }
    }
}

public struct InvitationStateMachine {
    public static func canRespond(_ status: InvitationStatus) -> Bool {
        status == .pending
    }

    public static func nextStatus(current: InvitationStatus, accept: Bool) -> InvitationStatus? {
        guard current == .pending else { return nil }
        return accept ? .accepted : .declined
    }

    public static func cancel(_ status: InvitationStatus) -> InvitationStatus? {
        guard status == .pending else { return nil }
        return .cancelled
    }

    public static func isDuplicate(existing: [InvitationStatus]) -> Bool {
        existing.contains(.pending)
    }
}
