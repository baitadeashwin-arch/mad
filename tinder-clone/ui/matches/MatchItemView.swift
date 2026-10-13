//
//  MatchItemView.swift
//  AntiSocial
//
//  Created by Alejandro Piguave on 23/1/22.
//  Updated for AntiSocial on 16/8/26.
//

import SwiftUI

struct MatchItemView: View {
    let model: MatchModel
    var body: some View {
        HStack(spacing: 12) {
            Image(uiImage: model.picture)
                .centerCropped()
                .frame(width: 56, height: 56)
                .cornerRadius(28)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(model.name).bold().font(.body)
                    Text("\(model.age)").fontWeight(.light).font(.subheadline)
                    
                    if let mode = model.connectionMode {
                        Text(LocalizedStringKey(mode.badgeKey))
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(8)
                    }
                }
                
                if let college = model.college, !college.isEmpty {
                    Text(college)
                        .font(.caption2)
                        .foregroundColor(AppColor.blueGray)
                }
                
                Text(model.lastMessage ?? NSLocalizedString("say-something-nice", comment: "Prompt to start chatting"))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct MatchItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            MatchItemView(model: MatchModel(id: "1", timestamp: Date(), userId: "u1", name: "Elon", birthDate: Date(), picture: UIImage(named: "elon_musk") ?? UIImage(), lastMessage: nil, connectionMode: .party, college: "Stanford University"))
        }
    }
}
