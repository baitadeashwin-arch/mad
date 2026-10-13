//
//  MessageModel.swift
//  tinder-clone
//
//  Created by Alejandro Piguave on 24/1/22.
//

import Foundation

struct MessageModel: Identifiable, Equatable{
    let id: String
    let isCurrentUser: Bool
    let timestamp: Date
    let message: String
    let type: SocialMessageType
    
    static func from(id: String, _ msg: FirestoreMessage, currentUserId: String) -> MessageModel{
        let resolvedType = SocialMessageType(rawValue: msg.type ?? SocialMessageType.text.rawValue) ?? .text
        return MessageModel(
            id: id,
            isCurrentUser: msg.senderId == currentUserId,
            timestamp: msg.timestamp ?? Date(),
            message: msg.message,
            type: resolvedType
        )
    }
}
