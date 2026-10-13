import Foundation
import SwiftUI

enum AppTab: Hashable {
    case discover, nearby, events, messages, profile
}

final class AppSession: ObservableObject {
    @Published var selectedTab: AppTab = .discover
    @Published var pendingChatMatch: MatchModel?
}
