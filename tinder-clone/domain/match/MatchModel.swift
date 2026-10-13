//
//  MatchModel.swift
//  AntiSocial
//
//  Created by Alejandro Piguave on 23/1/22.
//  Updated for AntiSocial on 16/8/26.
//

import UIKit

struct MatchModel: Identifiable {
    let id: String
    let timestamp: Date
    let userId: String
    let name: String
    let birthDate: Date
    let picture: UIImage
    let lastMessage: String?
    let connectionMode: ConnectionMode?
    let college: String?
    
    var age: Int {
        Date().years(from: birthDate)
    }
    
    init(
        id: String,
        timestamp: Date,
        userId: String,
        name: String,
        birthDate: Date,
        picture: UIImage,
        lastMessage: String? = nil,
        connectionMode: ConnectionMode? = .both,
        college: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.userId = userId
        self.name = name
        self.birthDate = birthDate
        self.picture = picture
        self.lastMessage = lastMessage
        self.connectionMode = connectionMode
        self.college = college
    }
}
