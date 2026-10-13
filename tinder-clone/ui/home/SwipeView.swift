//
//  SwipeView.swift
//  AntiSocial
//
//  Created by Alejandro Piguave on 1/1/22.
//  Updated for AntiSocial on 16/8/26.
//

import SwiftUI

enum SwipeAction{
    case swipeLeft, swipeRight, swipeParty, doNothing
}

struct SwipeView: View {
    @Binding var profiles: [ProfileCardModel]
    @State var swipeAction: SwipeAction = .doNothing
    //Bool: true if it was a like (swipe to the right / connect)
    var onSwiped: (ProfileCardModel, Bool) -> ()
    
    var body: some View {
        VStack{
            Spacer()
            VStack{
                ZStack{
                    EmptyStateView(
                        systemImage: "sparkles",
                        title: "No matches",
                        message: "You're all caught up. Check Nearby or Events to keep discovering people."
                    )
                    ForEach(profiles.indices, id: \.self){ index in
                        let model: ProfileCardModel = profiles[index]
                        
                        if(index == profiles.count - 1){
                            SwipeableCardView(model: model, swipeAction: $swipeAction, onSwiped: performSwipe)
                        } else if(index == profiles.count - 2){
                            SwipeCardView(model: model)
                        }
                    }
                }
            }.padding()
            Spacer()
            HStack{
                Spacer()
                GradientOutlineButton(action:{swipeAction = .swipeLeft}, iconName: "multiply", colors: AppColor.dislikeColors)
                    .accessibilityLabel("Pass")
                Spacer()
                GradientOutlineButton(action: {swipeAction = .swipeRight}, iconName: "heart.fill", colors: AppColor.likeColors)
                    .accessibilityLabel("Like")
                Spacer()
                GradientOutlineButton(action: {swipeAction = .swipeParty}, iconName: "gift.fill", colors: AppColor.partyColors)
                    .accessibilityLabel("Party Connect")
                Spacer()
            }.padding(.bottom)
        }
    }
    
    private func performSwipe(userProfile: ProfileCardModel, hasLiked: Bool){
        removeTopItem()
        onSwiped(userProfile, hasLiked)
    }
    
    private func removeTopItem(){
        profiles.removeLast()
    }
}

//Swipe functionality
struct SwipeableCardView: View {

    private let passText = "PASS"
    private let connectText = "CONNECT"
    private let screenWidthLimit = UIScreen.main.bounds.width * 0.5
    
    let model: ProfileCardModel
    @State private var dragOffset = CGSize.zero
    @Binding var swipeAction: SwipeAction
    
    var onSwiped: (ProfileCardModel, Bool) -> ()
    
    var body: some View {
        SwipeCardView(model: model)
            .overlay(
                HStack{
                    Text(connectText).font(.title2).bold().foregroundGradient(colors: AppColor.likeColors).padding(10).overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(LinearGradient(gradient: .init(colors: AppColor.likeColors),
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing), lineWidth: 3)
                    ).rotationEffect(.degrees(-20)).opacity(getLikeOpacity())
                    Spacer()
                    Text(passText).font(.title2).bold().foregroundGradient(colors: AppColor.dislikeColors).padding(10).overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(LinearGradient(gradient: .init(colors: AppColor.dislikeColors),
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing), lineWidth: 3)
                    ).rotationEffect(.degrees(20)).opacity(getDislikeOpacity())

                }.padding(.top, 45).padding(.leading, 20).padding(.trailing, 20)
                ,alignment: .top)
            .offset(x: self.dragOffset.width,y: self.dragOffset.height)
            .rotationEffect(.degrees(self.dragOffset.width * -0.06), anchor: .center)
            .simultaneousGesture(DragGesture(minimumDistance: 0.0).onChanged{ value in
                self.dragOffset = value.translation
            }.onEnded{ value in
                performDragEnd(value.translation)
            }).onChange(of: swipeAction, perform: { newValue in
                if newValue != .doNothing {
                    performSwipe(newValue == .swipeLeft ? .swipeLeft : .swipeRight)
                }
            })
    }
    
    private func performSwipe(_ swipeAction: SwipeAction){
        withAnimation(.linear(duration: 0.3)){
            if(swipeAction == .swipeRight){
                self.dragOffset.width += screenWidthLimit * 2
            } else if(swipeAction == .swipeLeft){
                self.dragOffset.width -= screenWidthLimit * 2
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSwiped(model, swipeAction == .swipeRight)
        }
        self.swipeAction = .doNothing
    }
    
    private func performDragEnd(_ translation: CGSize){
        let translationX = translation.width
        if(hasLiked(translationX)){
            withAnimation(.linear(duration: 0.3)){
                self.dragOffset = translation
                self.dragOffset.width += screenWidthLimit
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onSwiped(model, true)
            }
        } else if(hasDisliked(translationX)){
            withAnimation(.linear(duration: 0.3)){
                self.dragOffset = translation
                self.dragOffset.width -= screenWidthLimit
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onSwiped(model, false)
            }
        } else{
            withAnimation(.default){
                self.dragOffset = .zero
            }
        }
    }
    
    private func hasLiked(_ value: Double) -> Bool{
        let ratio: Double = dragOffset.width / screenWidthLimit
        return ratio >= 1
    }
    
    private func hasDisliked(_ value: Double) -> Bool{
        let ratio: Double = -dragOffset.width / screenWidthLimit
        return ratio >= 1
    }
    
    private func getLikeOpacity() -> Double{
        let ratio: Double = dragOffset.width / screenWidthLimit
        if(ratio >= 1){
            return 1.0
        } else if(ratio <= 0){
            return 0.0
        } else {
            return ratio
        }
    }
    
    private func getDislikeOpacity() -> Double{
        let ratio: Double = -dragOffset.width / screenWidthLimit
        if(ratio >= 1){
            return 1.0
        } else if(ratio <= 0){
            return 0.0
        } else {
            return ratio
        }
    }
}

//Card design
struct SwipeCardView: View {
    let model: ProfileCardModel
    
    @State private var currentImageIndex: Int = 0
    
    var body: some View {
        ZStack(alignment: .bottom){
            GeometryReader{ geometry in
                if !model.pictures.isEmpty && currentImageIndex < model.pictures.count {
                    Image(uiImage: model.pictures[currentImageIndex])
                        .centerCropped()
                        .gesture(DragGesture(minimumDistance: 0).onEnded({ value in
                            if value.translation.equalTo(.zero){
                                if(value.location.x <= geometry.size.width/2){
                                    showPrevPicture()
                                } else { showNextPicture()}
                            }
                        }))
                }
            }
            
            // Bottom gradient shadow for readability
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 180)
            
            VStack(alignment: .leading, spacing: 6){
                // Top Progress Indicators
                if(model.pictures.count > 1){
                    HStack{
                        ForEach(0..<model.pictures.count, id: \.self){ index in
                            Rectangle().frame(height: 3).foregroundColor(index == currentImageIndex ? .white : .gray).opacity(index == currentImageIndex ? 1 : 0.5)
                        }
                    }
                    .padding(.top, 6)
                    .padding(.horizontal)
                }
                
                // Top Mode Badge
                if let mode = model.connectionMode {
                    HStack {
                        Text(LocalizedStringKey(mode.badgeKey))
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                
                Spacer()
                
                // Bottom Profile Details
                DiscoverMetaView(model: model)
                    .padding()
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(0.7, contentMode: .fit)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
    
    private func showNextPicture(){
        if currentImageIndex < model.pictures.count - 1 {
            currentImageIndex += 1
        }
    }
    
    private func showPrevPicture(){
        if currentImageIndex > 0 {
            currentImageIndex -= 1
        }
    }
}

struct DiscoverMetaView: View {
    let model: ProfileCardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let score = model.compatibilityScore {
                Text("🔥 \(score)% Match")
                    .font(.headline.weight(.heavy))
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(model.name), \(model.age)").font(.title).fontWeight(.bold)
                Spacer()
            }
            if let college = model.college, !college.isEmpty {
                HStack(spacing: 4) {
                    Text("🎓 \(college)")
                    if model.collegeVerified {
                        Text("✓ College Verified").font(.caption.weight(.semibold))
                    }
                }
                .font(.subheadline)
            }
            if let distance = model.approximateDistanceText {
                Text("📍 \(distance)").font(.subheadline)
            }
            if let bio = model.bio, !bio.isEmpty {
                Text(bio).font(.footnote).lineLimit(2).opacity(0.9)
            }
            if let interests = model.commonInterests, !interests.isEmpty {
                Text("Common interests:")
                    .font(.caption.weight(.semibold))
                HStack(spacing: 6) {
                    ForEach(interests.prefix(3), id: \.self) { interest in
                        Text(interest)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
            }
            if let party = model.matchScore?.sharedPartyName {
                Text("🎉 Going to: \(party)")
                    .font(.footnote.weight(.semibold))
            }
            if let reasons = model.matchScore?.reasons, !reasons.isEmpty {
                ForEach(reasons, id: \.self) { reason in
                    Text("✓ \(reason.title)").font(.caption2)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(model.name), \(model.age), \(model.compatibilityScore ?? 0) percent match")
    }
}

struct SwipeView_Previews: PreviewProvider {
    @State static private var profiles: [ProfileCardModel] = [
        ProfileCardModel(
            userId: "1",
            name: "Alex",
            age: 22,
            pictures: [UIImage(named: "elon_musk") ?? UIImage()],
            bio: "Exploring downtown, looking for live concerts and party crews!",
            college: "Stanford University",
            connectionMode: .party,
            interests: ["🎉 House Parties", "🎶 Live Music & Concerts"]
        )
    ]
    static var previews: some View {
        SwipeView(profiles: $profiles, onSwiped: {_,_ in})
    }
}
