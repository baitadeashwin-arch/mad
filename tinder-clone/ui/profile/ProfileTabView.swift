import SwiftUI

struct ProfileTabView: View {
    @EnvironmentObject var contentViewModel: ContentViewModel
    @StateObject private var editProfileViewModel = EditProfileViewModel()
    @State private var showSignOut = false

    var body: some View {
        List {
            if let user = editProfileViewModel.userProfile {
                Section {
                    HStack(spacing: 16) {
                        if let picture = editProfileViewModel.userPictures.first?.picture {
                            Image(uiImage: picture)
                                .centerCropped()
                                .frame(width: 72, height: 72)
                                .cornerRadius(36)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(user.name), \(user.age)").font(.title3.weight(.bold))
                            if let college = user.college, !college.isEmpty {
                                HStack {
                                    Text("🎓 \(college)")
                                    if user.collegeVerified == true {
                                        Text("✓ College Verified")
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            Text((user.connectionMode ?? .both).titleKey)
                                .font(.caption)
                        }
                    }
                    Text(user.bio)
                    if let interests = user.interests, !interests.isEmpty {
                        FlexibleInterestText(interests: interests)
                    }
                }
            }

            Section("Settings") {
                NavigationLink("Edit Profile") { EditProfileView() }
                NavigationLink("Privacy") { PrivacySettingsView() }
                NavigationLink("Nearby Mode") { PrivacySettingsView() }
                NavigationLink("Notifications") { NotificationsSettingsView() }
                NavigationLink("Blocked Users") { BlockedUsersView() }
                NavigationLink("Help") { HelpView() }
                Button("Logout", role: .destructive) { showSignOut = true }
            }
        }
        .navigationTitle("Profile")
        .onAppear { editProfileViewModel.fetchProfile() }
        .alert("sign-out-confirmation", isPresented: $showSignOut, actions: {
            Button("yes", action: contentViewModel.signOut)
            Button("cancel", role: .cancel) {}
        })
    }
}

struct FlexibleInterestText: View {
    let interests: [String]
    var body: some View {
        Text(interests.joined(separator: "  "))
            .font(.caption)
    }
}

struct NotificationsSettingsView: View {
    var body: some View {
        List {
            Text("Notification architecture is ready for New Match, New Message, Party Invitation, Invitation Accepted, Party Starting, New Party, and AI Recommendation.")
            Text("Production push notifications need an Apple Developer account, an APNs key, and Firebase Cloud Messaging. See SETUP.md.")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Notifications")
    }
}

struct HelpView: View {
    var body: some View {
        List {
            Text("AntiSocial helps you discover people, parties, and campus events. Location is optional and always approximate.")
            Text("Never share exact meeting details in public event descriptions.")
        }
        .navigationTitle("Help")
    }
}
