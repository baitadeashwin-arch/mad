//
//  UserFacingError.swift
//  AntiSocial
//

import Foundation
import FirebaseAuth

enum UserFacingError {
    static func message(from error: Error) -> String {
        // If it is our own typed error, use its message directly.
        if let authErr = error as? AuthErrorModel {
            return classify(authErr.message)
        }

        // For raw Firebase Auth NSErrors, use the error code for reliable classification.
        let nsError = error as NSError
        if nsError.domain == AuthErrorDomain {
            switch AuthErrorCode(rawValue: nsError.code) {
            case .wrongPassword, .invalidCredential, .invalidEmail, .userNotFound:
                return "Those sign-in details didn't match. Try again."
            case .emailAlreadyInUse:
                return "That email is already registered."
            case .weakPassword:
                return "Choose a stronger password (at least 6 characters)."
            case .networkError:
                return "Check your internet connection and try again."
            case .userDisabled:
                return "This account has been disabled. Contact support."
            case .tooManyRequests:
                return "Too many attempts. Please wait a moment and try again."
            default:
                break
            }
        }

        if nsError.domain == NSURLErrorDomain {
            return "Check your internet connection and try again."
        }

        if error is StorageError {
            return "We couldn't upload that photo. Please try again."
        }

        return classify(error.localizedDescription)
    }

    // Keyword-based fallback used for AuthErrorModel messages (which are already localised strings).
    private static func classify(_ text: String) -> String {
        let lowered = text.lowercased()

        if lowered.contains("invalid credential") || lowered.contains("invalid-credential")
            || (lowered.contains("password") && lowered.contains("wrong"))
            || lowered.contains("user not found") || lowered.contains("user-not-found")
            || lowered.contains("no user record") {
            return "Those sign-in details didn't match. Try again."
        }
        if lowered.contains("already in use") || lowered.contains("email already") {
            return "That email is already registered."
        }
        if lowered.contains("invalid email") {
            return "Enter a valid email address."
        }
        if lowered.contains("weak password") {
            return "Choose a stronger password (at least 6 characters)."
        }
        if lowered.contains("network") || lowered.contains("internet") {
            return "Check your internet connection and try again."
        }
        if lowered.contains("too many") || lowered.contains("quota") {
            return "Too many attempts. Please wait a moment and try again."
        }
        if lowered.contains("permission") {
            return "You don't have access to that information."
        }
        if lowered.contains("location") {
            return "Location is unavailable. You can keep using Discover and Events."
        }
        return text.isEmpty ? "Something went wrong. Please try again." : text
    }
}
