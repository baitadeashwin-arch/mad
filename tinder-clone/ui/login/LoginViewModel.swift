import Foundation
import SwiftUI

class LoginViewModel: NSObject, ObservableObject {
    @Published var loginError: String? = nil
    @Published var isLoading: Bool = false

    private let profileRepository = ProfileRepository.shared

    func signIn(controller: UIViewController) async {
        await run {
            try await self.profileRepository.signIn(controller: controller)
        }
    }

    func signIn(email: String, password: String) async {
        await run {
            try await self.profileRepository.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
        }
    }

    func resetPassword(email: String) async {
        await run {
            try await self.profileRepository.sendPasswordReset(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private func run(_ work: @escaping () async throws -> Void) async {
        await MainActor.run {
            self.isLoading = true
            self.loginError = nil
        }
        do {
            try await work()
            await MainActor.run { self.isLoading = false }
        } catch {
            await MainActor.run {
                self.loginError = UserFacingError.message(from: error)
                self.isLoading = false
            }
        }
    }
}
