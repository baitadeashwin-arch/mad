//
//  Constants.swift
//  AntiSocial
//
//  Created by Alejandro Piguave on 18/1/22.
//  Updated for AntiSocial on 16/8/26.
//

import Foundation

struct InterestCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let weight: Int
    
    var displayName: String {
        "\(icon) \(name)"
    }
}

class Constants {
    static let genderOptions = ["man", "woman"]
    
    static let minInterestsCount = 3
    static let maxInterestsCount = 10
    
    static let interestCategories: [InterestCategory] = [
        InterestCategory(id: "music", name: "Music", icon: "🎵", weight: 20),
        InterestCategory(id: "movies", name: "Movies", icon: "🎬", weight: 20),
        InterestCategory(id: "food", name: "Food", icon: "🍕", weight: 15),
        InterestCategory(id: "gaming", name: "Gaming", icon: "🎮", weight: 15),
        InterestCategory(id: "sports", name: "Sports", icon: "⚽", weight: 10),
        InterestCategory(id: "travel", name: "Travel", icon: "✈️", weight: 10),
        InterestCategory(id: "technology", name: "Technology", icon: "💻", weight: 10),
        InterestCategory(id: "fitness", name: "Fitness", icon: "🏋️", weight: 10),
        InterestCategory(id: "photography", name: "Photography", icon: "📸", weight: 8),
        InterestCategory(id: "art", name: "Art", icon: "🎨", weight: 8),
        InterestCategory(id: "reading", name: "Reading", icon: "📚", weight: 8),
        InterestCategory(id: "dance", name: "Dance", icon: "💃", weight: 8),
        InterestCategory(id: "fashion", name: "Fashion", icon: "👗", weight: 8),
        InterestCategory(id: "books", name: "Books", icon: "📖", weight: 8),
        InterestCategory(id: "outdoor", name: "Outdoor Activities", icon: "🏕️", weight: 8)
    ]
    
    static var availableInterests: [String] {
        interestCategories.map { $0.displayName }
    }
}
