import Foundation
import UIKit

struct CreateProfileModel {
    let name: String
    let birthDate: Date
    let bio: String
    let isMale: Bool
    let orientation: Orientation
    let pictures: [UIImage]
    let connectionMode: ConnectionMode
    let college: String
    let collegeEmail: String
    let interests: [String]
    let nearbyEnabled: Bool
    let email: String?
    let password: String?
}
