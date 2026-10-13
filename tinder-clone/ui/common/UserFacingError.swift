//
//  UserFacingError.swift
//  AntiSocial
//

import Foundation

enum UserFacingError {
    static func message(from error: Error) -> String {
        let nsError = error as NSError
        let text = (error as? AuthErrorModel)?.message ?? error.localizedDescription
        let lowered = text.lowercased()

        if lowered.contains("password") && lowered.contains("wrong") {
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
        if nsError.domain == NSURLErrorDomain || lowered.contains("network") {
            return "Check your internet connection and try again."
        }
        if error is StorageError {
            return "We couldn't upload that photo. Please try again."
        }
        if lowered.contains("permission") || nsError.code == 7 {
            return "You don't have access to that information."
        }
        if lowered.contains("location") {
            return "Location is unavailable. You can keep using Discover and Events."
        }
        return "Something went wrong. Please try again."
    }
}
