//
//  SafetyRules.swift
//  AntiSocial
//

import Foundation

struct BlockFilter {
    let blockedUserIDs: Set<String>

    init(blockedUserIDs: Set<String>) {
        self.blockedUserIDs = blockedUserIDs
    }

    func shouldHide(userID: String) -> Bool {
        blockedUserIDs.contains(userID)
    }

    func visible<T>(_ items: [T], userID: (T) -> String) -> [T] {
        items.filter { !shouldHide(userID: userID($0)) }
    }
}

struct InvitationStateMachine {
    static func canRespond(_ status: InvitationStatus) -> Bool {
        status == .pending
    }

    static func nextStatus(current: InvitationStatus, accept: Bool) -> InvitationStatus? {
        guard current == .pending else { return nil }
        return accept ? .accepted : .declined
    }

    static func cancel(_ status: InvitationStatus) -> InvitationStatus? {
        guard status == .pending else { return nil }
        return .cancelled
    }

    static func isDuplicate(existing: [InvitationStatus]) -> Bool {
        existing.contains(.pending)
    }
}
