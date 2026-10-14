//
//  AuthRemoteDataSource.swift
//  tinder-clone
//
//  Created by Alejandro Piguave on 8/6/23.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
#if canImport(FirebaseFirestoreSwift)
import FirebaseFirestoreSwift
#endif
import GoogleSignIn
import SwiftUI

class AuthRemoteDataSource {

    private init() {}

    static let shared = AuthRemoteDataSource()

    // MARK: - Email / Password

    func signInWithEmail(email: String, password: String) async throws {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            throw AuthErrorModel(message: error.localizedDescription)
        }
    }

    func registerWithEmail(email: String, password: String) async throws {
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            throw AuthErrorModel(message: error.localizedDescription)
        }
    }

    func sendPasswordReset(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw AuthErrorModel(message: error.localizedDescription)
        }
    }

    // MARK: - Google Sign-In (GoogleSignIn SDK v7+)

    func signIn(controller: UIViewController, authType: AuthTypeModel) async throws {
        do {
            // v7 API: returns GIDSignInResult directly (no GIDConfiguration needed)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: controller)
            let user = result.user

            guard let userEmail = user.profile?.email else {
                throw AuthErrorModel(message: "Empty e-mail address")
            }

            // fetchSignInMethods is deprecated in Firebase 12 but still compiles.
            // Wrap in do/catch so it degrades gracefully if removed in a future SDK.
            let isNewUser: Bool
            do {
                let methods = try await Auth.auth().fetchSignInMethods(forEmail: userEmail)
                isNewUser = methods.isEmpty
            } catch {
                // If the call fails assume existing user to avoid blocking sign-in.
                isNewUser = false
            }

            switch authType {
            case .newUser where !isNewUser:
                throw AuthErrorModel(message: "User must be new.")
            case .existingUser where isNewUser:
                throw AuthErrorModel(message: "User must already exist.")
            default: break
            }

            // v7: tokens are on user.idToken and user.accessToken (not .authentication)
            guard let idToken = user.idToken?.tokenString else {
                throw AuthErrorModel(message: "No ID token found.")
            }
            let accessToken = user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: accessToken)
            try await Auth.auth().signIn(with: credential)

        } catch let authErr as AuthErrorModel {
            // Re-throw our own errors directly without double-wrapping.
            throw authErr
        } catch {
            throw AuthErrorModel(message: error.localizedDescription)
        }
    }
}
