//
//  ContentMessageView.swift
//  tinder-clone
//
//  Created by Alejandro Piguave on 24/1/22.
//

import SwiftUI

struct ContentMessageView: View {
    var contentMessage: String
    var isCurrentUser: Bool
    
    var body: some View {
        Text(contentMessage)
            .padding(10)
            .foregroundColor(isCurrentUser ? Color.white : Color.primary)
            .background(isCurrentUser ? AppColor.appColors.first : Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
    }
}

struct ContentMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ContentMessageView(contentMessage: "Hey this is a sample message." , isCurrentUser: true)
    }
}
