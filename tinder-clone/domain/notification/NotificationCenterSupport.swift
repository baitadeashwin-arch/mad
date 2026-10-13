//
//  NotificationCenterSupport.swift
//  AntiSocial
//
//  Architecture only. Production APNs requires Apple Developer setup.
//

import Foundation
import UserNotifications

enum AntiSocialNotificationEvent: String {
    case newMatch
    case newMessage
    case partyInvitation
    case invitationAccepted
    case partyStarting
    case newParty
    case aiRecommendation
}

protocol NotificationRouting {
    func requestAuthorizationIfNeeded()
    func handle(event: AntiSocialNotificationEvent, title: String, body: String)
}

final class LocalNotificationRouter: NotificationRouting {
    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    func handle(event: AntiSocialNotificationEvent, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["event": event.rawValue]
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
