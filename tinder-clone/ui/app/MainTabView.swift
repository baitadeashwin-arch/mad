import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appSession: AppSession

    var body: some View {
        TabView(selection: $appSession.selectedTab) {
            NavigationView {
                HomeView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Discover", systemImage: "house.fill")
            }
            .tag(AppTab.discover)

            NavigationView {
                NearbyView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Nearby", systemImage: "location.fill")
            }
            .tag(AppTab.nearby)

            NavigationView {
                EventsView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Events", systemImage: "calendar")
            }
            .tag(AppTab.events)

            NavigationView {
                MessagesHubView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Messages", systemImage: "bubble.left.and.bubble.right.fill")
            }
            .tag(AppTab.messages)

            NavigationView {
                ProfileTabView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(AppTab.profile)
        }
        .accentColor(AppColor.appColors.first)
    }
}
