//
//  MatchListView.swift
//  AntiSocial
//
//  Created by Alejandro Piguave on 2/1/22.
//  Updated for AntiSocial on 16/8/26.
//

import SwiftUI

struct MatchListView: View {
    @StateObject private var matchListViewModel = MatchListViewModel()
    
    var body: some View {
        VStack{
            if(matchListViewModel.isLoading){
                ProgressView()
            }else {
                if(matchListViewModel.matchModels.isEmpty){
                    Text("no-matches-yet")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .padding()
                } else {
                    List(matchListViewModel.matchModels){ item in
                        NavigationLink(destination: ChatView(match: item)){
                            MatchItemView(model: item)
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("connections")
        .onAppear(perform: performOnAppear)
    }

    private func performOnAppear(){
        if matchListViewModel.isFirstFetching{
            matchListViewModel.fetchMatches()
        }
    }
}

struct MatchListView_Previews: PreviewProvider {
    static var previews: some View {
        MatchListView()
    }
}
