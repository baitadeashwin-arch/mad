//
//  HomeView.swift
//  AntiSocial
//
//  Created by Alejandro Piguave on 31/12/21.
//  Updated for AntiSocial on 16/8/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appSession: AppSession
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var showMatchView = false

    var body: some View {
        ZStack {
            VStack {
                if homeViewModel.isLoading {
                    FilledLoadingView()
                } else if let error = homeViewModel.error {
                    EmptyStateView(
                        systemImage: "wifi.exclamationmark",
                        title: "Couldn't load people",
                        message: error,
                        actionTitle: "Retry",
                        action: { homeViewModel.fetchProfiles() }
                    )
                } else {
                    SwipeView(
                        profiles: $homeViewModel.userProfiles,
                        onSwiped: { userModel, hasLiked in
                            homeViewModel.swipeUser(user: userModel, hasLiked: hasLiked)
                        }
                    )
                }
            }
            .onAppear(perform: performOnAppear)
            .onReceive(homeViewModel.$lastMatchProfile, perform: { newValue in
                if newValue != nil {
                    withAnimation {
                        showMatchView.toggle()
                    }
                }
            })
            
            if showMatchView {
                MatchView(
                    matchName: homeViewModel.lastMatchProfile?.name ?? "",
                    matchImage: homeViewModel.lastMatchProfile?.pictures.first ?? UIImage(),
                    onSendMessageButtonClicked: {
                        withAnimation { showMatchView = false }
                        appSession.selectedTab = .messages
                    },
                    onKeepSwipingClicked: {
                        withAnimation { showMatchView = false }
                    }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 28)
                    Text("app-name")
                        .font(.title3.weight(.heavy))
                        .foregroundGradient(colors: AppColor.appColors)
                }
            }

        }
    }

    private func performOnAppear() {
        if homeViewModel.isFirstFetching {
            homeViewModel.fetchProfiles()
        }
    }
}

// Connection Celebration View
struct MatchView: View {
    let matchName: String
    let matchImage: UIImage
    let onSendMessageButtonClicked: () -> ()
    let onKeepSwipingClicked: () -> ()
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            VStack(spacing: 8) {
                Text("its-a-match-title")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                Text(String(format: NSLocalizedString("its-a-match-text", comment: "Text for when two users connect"), matchName))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Image(uiImage: matchImage)
                .centerCropped()
                .aspectRatio(0.75, contentMode: .fit)
                .frame(maxHeight: 280)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            
            Button(action: onSendMessageButtonClicked) {
                Text("Start Chat")
                    .font(.body.weight(.bold))
                    .foregroundColor(Color(hex: "e83984"))
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(.white)
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            }
            .padding(.top, 8)
            
            Button(action: onKeepSwipingClicked) {
                Text("keep-swiping")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 8)
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: AppColor.appColors.map { $0.opacity(0.92) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
