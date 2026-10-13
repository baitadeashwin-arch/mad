import SwiftUI

struct ContentView: View {
    @EnvironmentObject var contentViewModel: ContentViewModel
    @StateObject private var appSession = AppSession()

    var body: some View {
        Group {
            switch contentViewModel.authState {
            case .loading:
                SplashView()
            case .logged:
                MainTabView()
                    .environmentObject(appSession)
            case .unlogged:
                NavigationView {
                    LoginView()
                }
                .navigationViewStyle(.stack)
            }
        }
        .onAppear {
            contentViewModel.updateAuthState()
        }
    }
}

struct SplashView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
            Text("AntiSocial")
                .font(.largeTitle.weight(.black))
            Text("AI-Powered Social Discovery & Party Companion")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            ProgressView()
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
