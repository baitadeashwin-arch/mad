//
//  tinder_cloneApp.swift
//  AntiSocial (tinder-clone)
//
//  Created by Alejandro Piguave on 1/1/22.
//

import SwiftUI
import FirebaseCore
import Firebase
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
            print("✅ [Firebase] FirebaseApp successfully configured.")
        } else {
            // Attempt standard configuration
            #if !DEBUG
            FirebaseApp.configure()
            #else
            print("⚠️ [Firebase] GoogleService-Info.plist not found in bundle. Please add GoogleService-Info.plist from your Firebase Console to the project.")
            #endif
        }

        // Verify database connection and perform background check
        Task {
            await FirebaseDatabaseManager.shared.checkDatabaseConnection()
        }

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct tinder_cloneApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject var contentViewModel = ContentViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .environmentObject(contentViewModel)
            }
            .navigationViewStyle(.stack)
        }
    }
}
