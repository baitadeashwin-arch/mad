//
//  MatchRepository.swift
//  AntiSocial
//
//  Created by Alejandro Piguave on 8/6/23.
//  Updated for AntiSocial on 16/8/26.
//

import Foundation

class MatchRepository {
    
    private init() {}
    
    static let shared = MatchRepository()
    private let storageDataSource: StorageRemoteDataSource = StorageRemoteDataSource.shared
    private let firestoreDataSource: FirestoreRemoteDataSource = FirestoreRemoteDataSource.shared
    
    func getMatches() async throws -> [MatchModel] {
        let matchedUsers = try await firestoreDataSource.getMatchedUsers()
        
        let matchedUsersMap = matchedUsers.reduce(into: [String: String]()) {
            if let id = $1.profile.id, let firstPic = $1.profile.pictures.first {
                $0[id] = firstPic
            }
        }
        
        let picturesMap = try await storageDataSource.getPictureFromUsers(usersMap: matchedUsersMap)
        
        let matchModels: [MatchModel] = picturesMap.compactMap { key, value in
            guard let matchProfile = matchedUsers.first(where: { $0.profile.id == key }),
                  let userId = matchProfile.profile.id else {
                return nil
            }
            
            return MatchModel(
                id: matchProfile.id,
                timestamp: matchProfile.timestamp,
                userId: userId,
                name: matchProfile.profile.name,
                birthDate: matchProfile.profile.birthDate,
                picture: value,
                lastMessage: nil,
                connectionMode: matchProfile.profile.connectionMode,
                college: matchProfile.profile.college
            )
        }
        
        return matchModels
    }
}
