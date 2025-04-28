//
//  MessageView.swift
//  Chat
//
//  Created by Alex.M on 23.05.2022.
//

import SwiftUI
import AVKit

public enum CustomMessageType : String, Decodable {
    case invite = "invite"
    case friendInvite = "friendinvite"
    case planInvite = "planinvite"
    case join = "join"
    case like = "like"
    case friend = "friend"
    case system = "system"
    case unknown = "unknown"  // Default case for unsupported or missing types
    
    init(from string: String?) {
            self = CustomMessageType(rawValue: string?.lowercased() ?? "") ?? .unknown
        }
    
    public static func getType(from string: String?) -> CustomMessageType {
            return CustomMessageType(rawValue: string?.lowercased() ?? "") ?? .unknown
    }
    
}

struct MessageView: View {

    @Environment(\.chatTheme) private var theme

    @ObservedObject var viewModel: ChatViewModel

    var message: Message
    let positionInUserGroup: PositionInUserGroup
    let chatType: ChatType
    let avatarSize: CGFloat
    let tapAvatarClosure: ChatView.TapAvatarClosure?
    let tapActionClosure: ChatView.TapActionClosure?
    let messageUseMarkdown: Bool
    let isDisplayingMessageMenu: Bool
    let showMessageTimeView: Bool
    
//    @State private var thumbnail: UIImage?
//    @State private var player: AVPlayer  // Initialized lazily
//    @State var showReelInvite = false



    @State var avatarViewSize: CGSize = .zero
    @State var statusSize: CGSize = .zero
    @State var timeSize: CGSize = .zero

    static let widthWithMedia: CGFloat = 204
    static let horizontalNoAvatarPadding: CGFloat = 8
    static let horizontalAvatarPadding: CGFloat = 8
    static let horizontalTextPadding: CGFloat = 12
    static let horizontalAttachmentPadding: CGFloat = 1 // for multiple attachments
    static let statusViewSize: CGFloat = 14
    static let horizontalStatusPadding: CGFloat = 8
    static let horizontalBubblePadding: CGFloat = 70

    @State private var requestStatus: String = ""
    @State private var shouldShowPlanInviteFullScreen: Bool = false

    var font: UIFont
    
    var OtherUserName: String {
        message.user.isCurrentUser ? "You" : message.user.name
    }

    enum DateArrangement {
        case hstack, vstack, overlay
    }

    var additionalMediaInset: CGFloat {
        message.attachments.count > 1 ? MessageView.horizontalAttachmentPadding * 2 : 0
    }

    var dateArrangement: DateArrangement {
        let timeWidth = timeSize.width + 10
        let textPaddings = MessageView.horizontalTextPadding * 2
        let widthWithoutMedia = UIScreen.main.bounds.width
        - (message.user.isCurrentUser ? MessageView.horizontalNoAvatarPadding : avatarViewSize.width)
        - statusSize.width
        - MessageView.horizontalBubblePadding
        - textPaddings

        let maxWidth = message.attachments.isEmpty ? widthWithoutMedia : MessageView.widthWithMedia - textPaddings
        let finalWidth = message.text.width(withConstrainedWidth: maxWidth, font: font, messageUseMarkdown: messageUseMarkdown)
        let lastLineWidth = message.text.lastLineWidth(labelWidth: maxWidth, font: font, messageUseMarkdown: messageUseMarkdown)
        let numberOfLines = message.text.numberOfLines(labelWidth: maxWidth, font: font, messageUseMarkdown: messageUseMarkdown)

        if numberOfLines == 1, finalWidth + CGFloat(timeWidth) < maxWidth {
            return .hstack
        }
        if lastLineWidth + CGFloat(timeWidth) < finalWidth {
            return .overlay
        }
        return .vstack
    }
    
    
    // logic for placing avatars
    var showAvatar: Bool {
        positionInUserGroup == .single
        || (chatType == .conversation && positionInUserGroup == .last)
        || (chatType == .comments && positionInUserGroup == .first) || message.type == .invite
    }

    var topPadding: CGFloat {
        if chatType == .comments { return 0 }
        return positionInUserGroup == .single || positionInUserGroup == .first ? 8 : 4
    }

    var bottomPadding: CGFloat {
        if chatType == .conversation { return 0 }
        return positionInUserGroup == .single || positionInUserGroup == .first ? 8 : 4
    }

    var body: some View {
        
        let messagePadvalue : CGFloat = message.user.isCurrentUser ? 7 : 9

        VStack{
            if message.type == .system{
                HStack(alignment: .bottom, spacing: 0) {
                    requestAcceptedView(message)
                        .foregroundColor(Color.white.opacity(0.5))
                    
                }
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
                .frame(maxWidth: UIScreen.main.bounds.width, alignment: .center)
            }
            else if message.type == .invite {
                
                HStack(alignment: .bottom, spacing: 0) {
                    
//                    avatarView
                    inviteView(message)
                        .opacity(requestStatus == "approved" || requestStatus == "rejected" ? 0.5 : 1)
                }
                .padding(.top, topPadding + 20)
                .padding(.bottom, bottomPadding + 20)
                .padding(.trailing, message.user.isCurrentUser ? MessageView.horizontalNoAvatarPadding : 0)
                //.padding(message.user.isCurrentUser ? .leading : .trailing, MessageView.horizontalBubblePadding)
                .padding(message.user.isCurrentUser ? .trailing : .leading, 5)
                .frame(maxWidth: UIScreen.main.bounds.width, alignment: message.user.isCurrentUser ? .trailing : .leading)
            }
            else if message.type == .planInvite {
                HStack(alignment: .bottom, spacing: 0) {
//                    avatarView

//                    let _ = debugPrint("🔴🔴🔴 \(message)")
                    PlanInviteView(message : message)
                    
                }
                .padding(.top, topPadding + 0.5)
                .padding(.bottom, bottomPadding + 0.5)
                .padding(.trailing, message.user.isCurrentUser ? MessageView.horizontalNoAvatarPadding : 0)
                .padding(message.user.isCurrentUser ? .trailing : .leading, 5)
                .frame(maxWidth: UIScreen.main.bounds.width, alignment: message.user.isCurrentUser ? .trailing : .leading)

            }
            else if message.type == .join {
                HStack(alignment: .bottom, spacing: 0) {
                    joinView(message)
                }
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
                .padding(.trailing, message.user.isCurrentUser ? MessageView.horizontalNoAvatarPadding : 0)
                //.padding(message.user.isCurrentUser ? .leading : .trailing, MessageView.horizontalBubblePadding)
                .padding(message.user.isCurrentUser ? .trailing : .leading, 5)
                .frame(maxWidth: UIScreen.main.bounds.width, alignment: message.user.isCurrentUser ? .trailing : .leading)
            }
            else if message.type == .like {
                HStack(alignment: .bottom, spacing: 0) {
                    
                    
                    likeView(message)
                }
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
                .padding(.trailing, message.user.isCurrentUser ? MessageView.horizontalNoAvatarPadding : 0)
                //.padding(message.user.isCurrentUser ? .leading : .trailing, MessageView.horizontalBubblePadding)
                .padding(message.user.isCurrentUser ? .trailing : .leading, 5)
                .frame(maxWidth: UIScreen.main.bounds.width, alignment: message.user.isCurrentUser ? .trailing : .leading)
            }
            else if message.type == .friend {
                
                HStack(alignment: .bottom, spacing: 0) {
                    
                    
                    friendView(message)
                }
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
                .padding(.trailing, message.user.isCurrentUser ? MessageView.horizontalNoAvatarPadding : 0)
                //.padding(message.user.isCurrentUser ? .leading : .trailing, MessageView.horizontalBubblePadding)
                .padding(message.user.isCurrentUser ? .trailing : .leading, 5)
                .frame(maxWidth: UIScreen.main.bounds.width, alignment: message.user.isCurrentUser ? .trailing : .leading)
            }
            else{
                HStack(alignment: .bottom, spacing: 0) {
                    
                    // 🌟 to display the avatar of other users in Chat
//                    if !message.user.isCurrentUser {
//                        avatarView
//                    }
                    
                    
                    VStack(alignment: message.user.isCurrentUser ? .trailing : .leading, spacing: 2) {
//                        let isReply = message.replyMessage != nil
                        
                        if !isDisplayingMessageMenu, let reply = message.replyMessage?.toMessage() {
                            
                            replyBubbleView(reply)
                                .opacity(0.8)
                                .padding(message.user.isCurrentUser ? .trailing : .leading, 0)
                                .padding(.top, 8)
//                                .overlay(alignment: message.user.isCurrentUser ? .trailing : .leading) {
//                                    Capsule()
//                                        .foregroundColor(Color.red)
//                                        .frame(width: 2)
//                                }
                            
                        }
                        bubbleView(message)
                    }
                    
                    
                    // only for current user (message status)
                    // hav to change the status to blue, when the user sees the msg
                    
//                    if message.user.isCurrentUser, let status = message.status {
//                        MessageStatusView(status: status) {
//                            if case let .error(draft) = status {
//                                viewModel.sendMessage(draft)
//                            }
//                        }
//                        .sizeGetter($statusSize)
//                    }

                }
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
                .padding(.trailing, message.user.isCurrentUser ? MessageView.horizontalNoAvatarPadding : 0)
                .padding(message.user.isCurrentUser ? .leading : .trailing, MessageView.horizontalBubblePadding)
                .frame(maxWidth: UIScreen.main.bounds.width, alignment: message.user.isCurrentUser ? .trailing : .leading)
            }
        }
        .padding(message.user.isCurrentUser ? .trailing : .leading, messagePadvalue)
        .onAppear{
            self.requestStatus = message.requestStatus ?? ""
        }
    }

    @ViewBuilder
    func bubbleView(_ message: Message) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // message attachments
            if !message.attachments.isEmpty {
                attachmentsView(message)
                    .padding(.horizontal, 1.5)
                    .padding(.top, 1.5)
            }

            // message UI
            if !message.text.isEmpty {
                textWithTimeView(message)
                    .font(Font(font))
            }

            
            if let recording = message.recording {
                VStack(alignment: .trailing, spacing: 8) {
                    recordingView(message, isreply: false)
                    messageTimeView()
                        .padding(.bottom, 3)
                        .padding(.trailing, 5)
                }
            }
        }
        
        .bubbleBackground(message, theme: theme)
    }
    

    @ViewBuilder
    func replyBubbleView(_ message: Message) -> some View {
            VStack(alignment: .leading, spacing: 0) {
                Text(message.user.isCurrentUser ? "You" : message.user.name)
                    .fontWeight(.semibold)
                    .font(.system(size: 13))
                    .foregroundColor(message.user.isCurrentUser ? Color(hex: "e8b717") : Color.white)
                    .padding(.horizontal, MessageView.horizontalTextPadding)
                
                Group {
                    if !message.text.isEmpty && (!message.attachments.isEmpty || message.recording != nil) {
                        HStack(alignment: .center, spacing: message.text.count < 10 ? 4 : 8) {
                            Text(message.text)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .padding(.leading, MessageView.horizontalTextPadding)
                                .frame(minWidth: 20, maxWidth: message.text.count < 10 ? 55 : 90, alignment: .center)

                            if !message.attachments.isEmpty {
                                attachmentsView(message)
                                    .frame(width: 60, height: 60)
                                    .aspectRatio(1, contentMode: .fill)
                                    .clipped()
                                    .cornerRadius(10)
                                    .padding(.trailing, message.text.count < 10 ? 4 : 10)
                            }

                            if let recording = message.recording {
                                recordingView(message, isreply: true)
                            }
                        }
                        .frame(maxWidth: message.text.count < 10 ? 120 : 150, alignment: .leading)
                        .background(Color(hex : "050505").opacity(0.6))
                        .cornerRadius(10)
                        .padding(.leading, 3)
                        .padding(.top, 5)
                    }
                    else {
                        // Show individual elements without a frame
                        if !message.text.isEmpty {
                            Text(message.text)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .padding(.vertical, 3)
                                .padding(.horizontal, MessageView.horizontalTextPadding)
                        } else if !message.attachments.isEmpty {
                            attachmentsView(message)
                                .frame(width: 100, height: 100)
                                .aspectRatio(1, contentMode: .fill)
                                .clipped()
                                .cornerRadius(10)
                                .padding(.horizontal, 5)
                                .padding(.leading, 2)
                                .padding(.top, 8)
                        } else if let recording = message.recording {
                            recordingView(message, isreply:true)
                        }
                    }
                }

            }
            .font(.caption2)
            .padding(.top, 8)
            .padding(.bottom, 5)
            .background(Color.gray.opacity(0.17))
            .overlay(
                    Rectangle()
                        .frame(width: 3) // Adjust thickness
                        .foregroundColor(message.user.isCurrentUser ? Color(hex: "e8b717") : Color.white) // Change color as needed
                        .opacity(0.8), // Adjust opacity if needed
                    alignment: .leading // Left side border
                )
            .cornerRadius(10)
            .padding(.trailing, 25)
        
        
        // .frame(width: message.attachments.isEmpty ? nil : MessageView.widthWithMedia + additionalMediaInset)
        /*.bubbleBackground(newMessage, theme: theme, isReply: true)*/
    }
    
    @ViewBuilder
    func requestAcceptedView(_ message: Message) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(message.text)
                .font(.caption2)
                .padding(.horizontal, MessageView.horizontalTextPadding)

        }
        .font(.caption2)
        .padding(.vertical, 8)
        .frame(width: message.attachments.isEmpty ? nil : MessageView.widthWithMedia + additionalMediaInset)
    }
    
    @ViewBuilder
    func inviteView(_ message: Message) -> some View {
        VStack(spacing: 2) {
            // Invite Header
            HStack(spacing: 5) {
                let isApprovedOrDeclined = requestStatus == "approved" || requestStatus == "rejected"
                let isCurrentUser = message.user.isCurrentUser
                
                // Determine the first text value
                let firstText = isCurrentUser
                    ? (isApprovedOrDeclined ? "Your" : "You")
                    : (isApprovedOrDeclined ? "You" : message.user.name)
                
                // Determine the second text value
                let secondText = isCurrentUser
                    ? (isApprovedOrDeclined ? "request has been \(requestStatus)" : "sent an invite")
                    : (isApprovedOrDeclined ? "\(requestStatus) the request" : "invites you")
                
                // Determine the text color
                let firstTextColor = isCurrentUser || isApprovedOrDeclined ? Color(hex: "e8b717") : Color.white
                let secondTextColor = isCurrentUser || isApprovedOrDeclined ? .gray.opacity(0.8) : Color(hex: "e8b717").opacity(0.8)
                
                Text(firstText)
                    .font(.system(size: 17))
                    .fontWeight(.bold)
                    .foregroundColor(firstTextColor)
                
                Text(secondText)
                    .font(.system(size: 14))
                    .font(.subheadline)
                    .foregroundColor(secondTextColor)
                    .padding(.top, 1)
            }            .padding(.horizontal)

            // Attachments (if available)
            if !message.attachments.isEmpty {
                attachmentsView(message)
                    .padding(.horizontal)
            }

            // Message Body (if available)
            if !message.text.isEmpty {
                HStack {
                    Text(message.text)
                        .font(.system(size: 11))
                        .multilineTextAlignment(.center) // Center text when wrapping
                        .fixedSize(horizontal: false, vertical: true) // Wraps text properly
                        .padding(.horizontal)
                        .padding(.top, 2)
                }
                .frame(minWidth: 0, maxWidth: 250, alignment: .center) // Center text without taking full width
            }



            // Accept / Decline Buttons
            actionButtons(for: message)
                .padding(.horizontal)
                .padding(.bottom, 2)
                .padding(.top, 3)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "131313"))
                .shadow(color: message.user.isCurrentUser ? Color(hex: "e8b717").opacity(0.4) : Color.white.opacity(0.4), radius: 3, x: 0, y: 0)
        )
        .padding(message.user.isCurrentUser ? .trailing : .leading, 5)
    }
    
    
    // -------------------- REEL Invite View-------------------
    struct ActionButtons4Reel: View {
        let width: CGFloat
        let height: CGFloat
        let fontsize: CGFloat
        let message: Message
        @State private var requestStatus: String = "pending"
        
        var body: some View {
            if (message.requestStatus == "pending" || requestStatus == "pending"), !message.user.isCurrentUser {
                if requestStatus != "approved" && requestStatus != "rejected" {
                    VStack(alignment: .center, spacing: 10) {
                        Button(action: {
                            if let attendanceGroupId = message.attendanceGroupId,
                               let receiverId = message.receiverId {
                                NotificationCenter.default.post(
                                    name: .updatePlanStatus,
                                    object: nil,
                                    userInfo: [
                                        "planId": attendanceGroupId,
                                        "receiverId": receiverId,
                                        "status": "confirmed"
                                    ]
                                )
                            }
                            if let groupId = message.attachments.first?.groupId,
                               let receiverId = message.receiverId,
                               message.isGroupInvite {
                                APIService.shared.acceptGroupInvite(groupId: groupId, userId: receiverId) { result in
                                    switch result {
                                        case .success(let response):
                                            print(response.message)
                                        case .failure(let error):
                                            print("Addition to group failed: \(error.localizedDescription)")
                                    }
                                }
                            }
                            requestStatus = "approved"
                        }) {
                            Text("Accept")
                                .foregroundColor(.black)
                                .font(.system(size: fontsize, weight: .regular))
                                .frame(width: width, height: height)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .opacity(0.75)
                        }
                        
                        Button(action: {
                            if let attendanceGroupId = message.attendanceGroupId,
                               let receiverId = message.receiverId {
                                NotificationCenter.default.post(
                                    name: .updatePlanStatus,
                                    object: nil,
                                    userInfo: [
                                        "planId": attendanceGroupId,
                                        "receiverId": receiverId,
                                        "status": "cancelled"
                                    ]
                                )
                            }
                            requestStatus = "rejected"
                        }) {
                            Text("Decline")
                                .foregroundColor(.white.opacity(0.75))
                                .font(.system(size: fontsize, weight: .regular))
                                .frame(width: width, height: height)
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
//                                .opacity(0.75)
                        }
                    }
                }
            }
        }
    }

    struct ReelInvite: View {
        @Environment(\.dismiss) var dismiss
        @State private var isPlaying = false  // Track play state
        @State private var showControls = false  // Show button initially

        @Binding var player: AVPlayer
        
        let venue: String
        let time: String
        let price: String
        let description : String
        let message: Message
        
        // receiver details
        let receiverName : String
        let receiverAge : String
//        let receiverImage

        var body: some View {
//            let _ = debugPrint("🌟 Reel Invite: \(venue) \(time) \(price) \(player.currentItem)")
            Group{
                if player.currentItem != nil{
                    ZStack {
                        VideoplayerView(player: player)
                            .onTapGesture {
                                showControls = true
                                hideControlsAfterDelay()
                            }
                        
                        BackButton()
                            .padding(.top, -400)
                            .padding(.leading, -200)
                        
                        ZStack{
                            ReelLinearGradient()
                                .allowsHitTesting(false)
                            
                            VStack{
                                Spacer()
                                    Location_Time_Price_View_Receiver(venue: venue, price: price, time: time)
                                    UserInfoView(name: receiverName, age: receiverAge, description: description, message: message)
                                        .padding()

                            }
                            .padding(.bottom, 70)
                        }
                        
                        if showControls {
                            Button(action: {
                                if isPlaying {
                                    player.pause()
                                } else {
                                    player.play()
                                }
                                isPlaying.toggle()
                                showControls = true  // Show controls again on interaction
                                hideControlsAfterDelay()
                            })
                            {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.white)
                                    .shadow(radius: 5)
                            }
                            .padding()
                        }
                    }
                }
                else {
                    LoadingView(width: 300, height: 300)
                }
            }
            .onAppear {
                    player.seek(to: .zero)
                    player.play()
                    isPlaying = true
           }
            .onDisappear {
                player.pause() // Stops playback
            }
        }

        private func hideControlsAfterDelay() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showControls = false
            }
        }
        
        private func ReelLinearGradient() -> some View {
            LinearGradient(
                gradient: Gradient(colors: [
                    .clear,
                    .black.opacity(0.3),
                    .black.opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        
        private func VideoplayerView(player : AVPlayer) -> some View {
            VideoPlayer(player: player)
                .ignoresSafeArea()
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .overlay(Color.black.opacity(0.1))
        }
        
        private func BackButton() -> some View {
            Button{
                dismiss()
            }
            label : {
                HStack{
                    Image(systemName: "chevron.left")
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .frame(width: 60, height:60)
                    
                    Text("Back")
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .foregroundColor(.white)
                        .padding(.leading, -23)
                    
                }
            }
        }
        
        private func Location_Time_Price_View_Receiver(venue : String, price : String, time : String) -> some View {
            HStack(alignment: .center){
                    Text(venue)
                        .foregroundColor(.white)
                        .font(.system(size: 23, weight: .bold, design: .default))
                        .padding(.leading, 12)
                                    
                Spacer()
                
                
                Text("\(time)")
                    .padding(.trailing, 10)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 0)
                
            }

        }
            
        private func Location_Time_Price_View_Sender(venue : String, price : String, time : String) -> some View {
            VStack(alignment: .center){

                    Text(venue)
                        .foregroundColor(.white)
                        .font(.system(size: 30, weight: .bold, design: .default))
                    
                Text("\(time)")
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 0)
                    .padding(.top, 3)
                
            }

        }
        
        private func UserInfoView(name: String, age: String, description: String, message: Message) -> some View{
            HStack(spacing: 10) {
                Button{}
                label : {
                    Circle()
                    // have to add the image here
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .background(Circle().fill(Color.gray.opacity(0.5)))
                    
                    VStack(alignment: .center, spacing: 2) {
                        HStack(alignment: .center) {
                            Text(name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("• \(age)")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                        
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.leading, 10)
                    
                    ActionButtons4Reel(width: 75, height: 35, fontsize: 15, message: message)
                        .padding(.trailing, -10)
                }
            }
        }
    }

    struct PlanInviteView: View {
        @State var thumbnail: UIImage? = nil
        @State var player: AVPlayer
        @State var showReelInvite = false

        let message: Message
        let location: String
        let time: String
        let price: String
        let description: String
        
        @State var isThumbnailLoaded: Bool = false

        let receiverName: String = "Daniel"
        let receiverAge: String = "103"

        let cropWidth: CGFloat = 170
        let cropHeight: CGFloat = 250

        init(message: Message) {
            self.message = message
            self.location = message.venueName ?? ""
            self.time = message.venueTime ?? ""
            self.price = message.venuePrice ?? ""
            self.description = message.AIdescription ?? ""
            if let firstAttachment = message.attachments.first {
                self._player = State(initialValue: AVPlayer(url: firstAttachment.full))
            } else {
                self._player = State(initialValue: AVPlayer())  // Fallback to empty player
            }
        }
                
        var body: some View {
                VStack(alignment: .center){
                    Button(action: { showReelInvite = true }) {
                        ZStack {
                            ReelThumbnailDisplay(url: message.attachments.first?.thumbnail, crop_width: cropWidth, crop_height: cropHeight, isThumbnailLoaded : $isThumbnailLoaded)

                            if isThumbnailLoaded{
                                Image(systemName: "play.circle")
                                    .renderingMode(.template)
                                    .resizable()
                                    .foregroundColor(Color.white)
                                    .frame(width: 18, height: 18)
                                    .offset(x: 65, y: -105)
                                    .shadow(color: Color.black, radius: 10, x: 0, y: 0)
                                
                    
                                ZStack {
                                    ReelLinearGradient()
                                    
                                    VStack{
                                        Location_Price_Time_Display_Receiver(location: location, price: price, time: time)
                                        InviterInfoDisplay(DpRadius: 40, name: receiverName, Age: receiverAge, Description: description)
                                            .padding(.top, 7)
                                    }
                                        .padding(.top, 125)
                                }
                                .frame(width: cropWidth, height: cropHeight)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .fullScreenCover(isPresented: $showReelInvite) {
                        if isThumbnailLoaded{
                            ReelInvite(player : $player, venue: location, time: time, price: price, description: description, message: message, receiverName: receiverName, receiverAge: receiverAge)
                        }
                    }
                    
//                    if isThumbnailLoaded{
//                        ActionButtons4Reel(width: cropWidth - 20, height: 30, fontsize: 15, message: message)
//                            .padding(.bottom, 10)
//                    }
                }
                .frame(width: cropWidth)
                .background(Color.clear.opacity(0.5))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white, lineWidth: 0.1)
                )
        }
        
        
        private func ReelLinearGradient() -> some View {
            LinearGradient(
                gradient: Gradient(colors: [
                    .clear,
                    .black.opacity(0.3),
                    .black.opacity(0.75),
                    .black.opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        
        private func ReelThumbnailDisplay(url: URL?, crop_width: CGFloat, crop_height: CGFloat, isThumbnailLoaded: Binding<Bool>) -> some View {
            Group {
                if let validURL = url {
                    AsyncImageView(url: validURL)
                        .frame(width: crop_width, height: crop_height)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay(
                            Rectangle()
                                .strokeBorder(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.5), Color.white.opacity(0.5), Color.clear]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                                .mask(
                                    RoundedRectangle(cornerRadius: 5)
                                        .padding(.bottom, 1)
                                )
                        )
                        .onAppear {
                            isThumbnailLoaded.wrappedValue = true
                        }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.gray.opacity(0.25), Color.gray.opacity(0.1), Color.black]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: crop_width, height: crop_height)

                        VStack {
                            Image(systemName: "video.slash") // Video error icon
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                            
                            Text("Video Unavailable")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }                    .onAppear {
                        isThumbnailLoaded.wrappedValue = false
                    }
                }
            }
        }
        
        private func InviterInfoDisplay(DpRadius : CGFloat, name : String, Age : String, Description : String) -> some View {
            Button {} label: {
                Circle()
                    .stroke(Color.white, lineWidth: 1.5)
                    .frame(width: DpRadius, height: DpRadius)
                    .background(Circle().fill(Color.gray.opacity(0.5)))
                    .padding(.leading, 8)
//                    .padding(.trailing, 10)
            
            
                VStack(alignment: .center, spacing: 2) {
                    HStack {
                        Text(name)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .padding(.leading, -5)
                        
                        Text(Age)
                            .font(.system(size: 9))
                            .foregroundColor(.white)
                            .padding(.leading, -5)
                    }
                    .padding(.leading, -3)
                    
                    Text(Description)
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.leading, 3)
            }
        }
        
        private func Location_Price_Time_Display_Sender(location: String, price: String, time: String) -> some View {
            VStack(alignment: .center) {
                Spacer()
                HStack{
                    Text(location)
                        .foregroundColor(.white)
                        .font(.system(size: 13, weight: .bold))

                }
                .padding(.bottom, 5)

                // date-time
                Text("\(time)")
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 20)
            }
            .padding(.bottom, 10)
        }
        
        private func Location_Price_Time_Display_Receiver(location: String, price: String, time: String) -> some View {
            HStack{
                Text(location)
                    .foregroundColor(.white)
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.leading, 5)

//                Text(price)
//                    .foregroundColor(.white)
//                    .font(.system(size: 10))
                
                Spacer()

                // date-time
                Text(time)
                    .font(.system(size: 9))
                    .padding(.trailing, 5)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 20)
            }
        }
    }
    
    struct LoadingView: View {
        let width : CGFloat
        let height : CGFloat
        var body: some View {
            ProgressView("Loading...")
                .progressViewStyle(CircularProgressViewStyle())
                .frame(width: width, height: height)
        }
    }
    // -------------------- REEL Invite View-------------------
    
    
    
    @ViewBuilder
    func joinView(_ message: Message) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(message.user.name) would like to join")
                .fontWeight(.semibold)
                .padding(.horizontal, MessageView.horizontalTextPadding)
                .padding(.top, 8)
            
            
            if !message.attachments.isEmpty {
                attachmentsView(message)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
            }

            if !message.text.isEmpty {
                MessageTextView(text: message.text, messageUseMarkdown: messageUseMarkdown)
                    .padding(.horizontal, MessageView.horizontalTextPadding)
                    .padding(.bottom, 8)
            }

           
            
           actionButtons(for: message)
            
        }
        .font(.caption2)
        .padding(.vertical, 0)
        .frame(width: message.attachments.isEmpty ? nil : MessageView.widthWithMedia + additionalMediaInset)
        .bubbleBackground(message, theme: theme, isReply: false)
    }
    
    
    @ViewBuilder
    func likeView(_ message: Message) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Extracting name, "Liked your post", and the rest of the message
            let parts = message.text.components(separatedBy: "Liked your post")
            var name = message.user.isCurrentUser ? "You" : parts.first ?? ""
            var postText = message.user.isCurrentUser ? "Liked the post" : parts.count > 1 ? "Liked your post" : ""
            let restText = parts.count > 1 ? parts.last ?? "" : ""
            

            // Heart Icon and Liked Message
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .padding(.top, 3)
                    .foregroundColor(Color.red)
                
                // Styled Text Composition
                (
                    Text(name).fontWeight(.bold).font(.system(size: 20)) +
                    Text(" \(postText)") +
                    Text(" \(restText)").italic().fontWeight(.bold)
                )
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            }
            .frame(maxWidth: message.attachments.isEmpty ? nil : MessageView.widthWithMedia)
            .fixedSize(horizontal: false, vertical: true) // Ensure text wraps correctly

            // Display Attachments (Image Below the Text)
            if !message.attachments.isEmpty {
                attachmentsView(message)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke((message.user.isCurrentUser ? Color(hex: "e8b717").opacity(0.2) : Color.white.opacity(0.2)),
                    lineWidth: 1)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.3)))
        )
    }
    @ViewBuilder
    func friendView(_  message: Message) -> some View {
       
        VStack(alignment: .leading, spacing: 0) {
          
            if !message.attachments.isEmpty {
                attachmentsView(message)
                    .padding(.top, 0)
                    .padding(.bottom, 4)
            }

            if !message.text.isEmpty {
                MessageTextView(text: message.text, messageUseMarkdown: messageUseMarkdown)
                    .padding(.horizontal, MessageView.horizontalTextPadding)
                    .padding(.bottom, 8)
            }

           
            
      
                actionButtons(for: message)
            
        }
        .font(.caption2)
        .padding(.vertical, 0)
        .frame(width: message.attachments.isEmpty ? nil : MessageView.widthWithMedia + additionalMediaInset)
        .bubbleBackground(message, theme: theme, isReply: false)
    }


    @ViewBuilder
    var avatarView: some View {
        Group {
            if showAvatar {
                AvatarView(url: message.user.avatarURL, avatarSize: avatarSize)
                    .contentShape(Circle())
                    .onTapGesture {
                        tapAvatarClosure?(message.user, message.id)
                    }
            } else {
                Color.clear.viewSize(avatarSize)
            }
        }
        .padding(.horizontal, MessageView.horizontalAvatarPadding)
        .sizeGetter($avatarViewSize)
    }

    @ViewBuilder
    func attachmentsView(_ message: Message) -> some View {
        AttachmentsGrid(attachments: message.attachments) {
            viewModel.presentAttachmentFullScreen($0)
        }
        .applyIf(message.attachments.count > 1) {
            $0
                .padding(.top, MessageView.horizontalAttachmentPadding)
                .padding(.horizontal, MessageView.horizontalAttachmentPadding)
        }
//        .overlay(alignment: .bottomTrailing) {
//            if message.text.isEmpty {
//                messageTimeView(needsCapsule: true)
//                    .padding(4)
//            }
//        }
        .contentShape(Rectangle())
    }

    func approveAction(for message: Message) {
            // Accept button action
            if let attendanceGroupId = message.attendanceGroupId,
               let receiverId = message.receiverId {
                NotificationCenter.default.post(
                    name: .updatePlanStatus,
                    object: nil,
                    userInfo: [
                        "planId": attendanceGroupId,
                        "receiverId": receiverId,
                        "status": "confirmed"
                    ]
                )
            }
            if let groupId = message.attachments.first?.groupId,
               let receiverId = message.receiverId,
               message.isGroupInvite {

                APIService.shared.acceptGroupInvite(groupId: groupId, userId: receiverId) { result in
                    switch result {
                        case .success(let response):
                            print(response.message)
                        case .failure(let error):
                            print("Addition to grp Failed: \(error.localizedDescription)")
                    }
                }
            }
            tapActionClosure?(message, "approved")
            requestStatus = "approved" // Update status to hide buttons
    }

    func rejectAction(for message: Message) {
        // Reject button action
        if let attendanceGroupId = message.attendanceGroupId,
           let receiverId = message.receiverId {
            NotificationCenter.default.post(
                name: .updatePlanStatus,
                object: nil,
                userInfo: [
                    "planId": attendanceGroupId,
                    "receiverId": receiverId,
                    "status": "cancelled"
                ]
            )
        }
        tapActionClosure?(message, "rejected")
        requestStatus = "rejected" // Update status to hide buttons
    }
    
    @ViewBuilder
    private func actionButtons(for message: Message) -> some View {
        // Check if the message request status is pending and the user is not the current user
        if (message.requestStatus == "pending" || requestStatus == "pending"), !message.user.isCurrentUser {
            // Check if the request status is neither approved nor rejected to show buttons
            if requestStatus != "approved" && requestStatus != "rejected" {
                HStack(spacing: 10) {
                    Button(action: {
                        // Accept button action
                        if let attendanceGroupId = message.attendanceGroupId,
                           let receiverId = message.receiverId {
                            NotificationCenter.default.post(
                                name: .updatePlanStatus,
                                object: nil,
                                userInfo: [
                                    "planId": attendanceGroupId,
                                    "receiverId": receiverId,
                                    "status": "confirmed"
                                ]
                            )
                        }
                        if let groupId = message.attachments.first?.groupId,
                           let receiverId = message.receiverId,
                           message.isGroupInvite {

                            APIService.shared.acceptGroupInvite(groupId: groupId, userId: receiverId) { result in
                                switch result {
                                    case .success(let response):
                                        print(response.message)
                                    case .failure(let error):
                                        print("Addition to grp Failed: \(error.localizedDescription)")
                                }
                            }
                        }
                        tapActionClosure?(message, "approved")
                        requestStatus = "approved" // Update status to hide buttons
                    }) {
                        Text("Accept")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "131313"))
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.8))
                            )
                            .padding(.trailing, 5)
                    }
                    
                    Button(action: {
                        // Reject button action
                        if let attendanceGroupId = message.attendanceGroupId,
                           let receiverId = message.receiverId {
                            NotificationCenter.default.post(
                                name: .updatePlanStatus,
                                object: nil,
                                userInfo: [
                                    "planId": attendanceGroupId,
                                    "receiverId": receiverId,
                                    "status": "cancelled"
                                ]
                            )
                        }
                        tapActionClosure?(message, "rejected")
                        requestStatus = "rejected" // Update status to hide buttons
                    }) {
                        Text("Reject")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.65))
                            )
                            .padding(.leading, 5)
                    }
                }
                .padding(.horizontal, MessageView.horizontalTextPadding)
//                .padding(.vertical, 8)
                .frame(maxWidth: MessageView.widthWithMedia)
            }
        }
    }
    
    @ViewBuilder
    func textWithTimeView(_ message: Message) -> some View {
        let messageView = MessageTextView(text: message.text, messageUseMarkdown: messageUseMarkdown)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, MessageView.horizontalTextPadding)

        let timeView = messageTimeView()
            .padding(.trailing, 7)
            
        Group {
            switch dateArrangement {
            case .hstack:
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    messageView
                    if !message.attachments.isEmpty {
                        Spacer()
                    }
                    timeView
                        .offset(x: 0, y: 6)

                }
                .padding(.vertical, 8)
            case .vstack:
                VStack(alignment: .leading, spacing: 4) {
                    messageView
                    HStack(spacing: 0) {
                        Spacer()
                        timeView
                            .offset(x: 0, y: 6)
                    }
                }
                .padding(.vertical, 8)
            case .overlay:
                messageView
                    .padding(.vertical, 8)
                    .overlay(alignment: .bottomTrailing) {
                        timeView
                            .padding(.vertical, 8)
                            .offset(x: 0, y: 5)
                    }
            }
        }
    }

    @ViewBuilder
    func recordingView(_ message: Message, isreply : Bool) -> some View {
        
//        let color: Color = isreply ? .white : .black

        
        if let recording = message.recording{
            RecordWaveformWithButtons(
                recording: recording,
                colorButton: message.user.isCurrentUser ?  Color(hex: "e8b717") : .white,
                colorButtonBg: message.user.isCurrentUser ? .black : Color.black,
                colorWaveform: message.user.isCurrentUser ? theme.colors.textDarkContext : .white
            )
            .padding(.horizontal, MessageView.horizontalTextPadding)
            .padding(.top, 8)
        }
    }

    func messageTimeView(needsCapsule: Bool = false) -> some View {
        Group {
            if showMessageTimeView {
                if needsCapsule {
                    MessageTimeWithCapsuleView(text: message.time, isCurrentUser: message.user.isCurrentUser, chatTheme: theme)
                } else {
                    MessageTimeView(text: message.time, isCurrentUser: message.user.isCurrentUser, chatTheme: theme)
                }
            }
        }
        .sizeGetter($timeSize)
    }
}

extension View {
    @ViewBuilder
    func bubbleBackground(_ message: Message, theme: ChatTheme, isReply: Bool = false) -> some View {
        let radius: CGFloat = !message.attachments.isEmpty ? 12 : 10
        let color = message.user.isCurrentUser ? Color(hex: "0a0a0a") : Color(hex: "1f1f1f")
        self
            .frame(width: message.attachments.isEmpty ? nil : MessageView.widthWithMedia)
            .foregroundColor(message.user.isCurrentUser ? Color.white : Color.white)
            .background {
                if isReply || !message.text.isEmpty || message.recording != nil {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(color)
                        .opacity(isReply ? 0.7 : 1)
                }
            }
            .overlay( // Border that follows the rounded shape
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(message.user.isCurrentUser ? Color(hex: "e8b717").opacity(0.4) : Color(hex: "1f1f1f").opacity(0.2), lineWidth: 0.5)
            )
    }
}

#if DEBUG
struct MessageView_Preview: PreviewProvider {
    static let stan = User(id: "stan", name: "Stan", avatarURL: nil, isCurrentUser: false)
    static let john = User(id: "john", name: "John", avatarURL: nil, isCurrentUser: true)

    static private var shortMessage = "Hi, buddy!"
    static private var longMessage = "Hello hello hello hello hello hello hello hello hello hello hello hello hello\n hello hello hello hello d d d d d d d d"

    static private var replyedMessage = Message(
        id: UUID().uuidString,
        user: stan,
        status: .read,
        text: longMessage,
        attachments: [
            Attachment.randomImage(),
            Attachment.randomImage(),
            Attachment.randomImage(),
            Attachment.randomImage(),
            Attachment.randomImage(),
        ]
    )

    static private var message = Message(
        id: UUID().uuidString,
        user: stan,
        status: .read,
        text: shortMessage,
        replyMessage: replyedMessage.toReplyMessage()
    )

    static var previews: some View {
        ZStack {
            Color.yellow.ignoresSafeArea()

            MessageView(
                viewModel: ChatViewModel(),
                message: replyedMessage,
                positionInUserGroup: .single,
                chatType: .conversation,
                avatarSize: 32,
                tapAvatarClosure: nil,
                tapActionClosure: nil,
                messageUseMarkdown: false,
                isDisplayingMessageMenu: false,
                showMessageTimeView: true,
                font: UIFontMetrics.default.scaledFont(for: UIFont.systemFont(ofSize: 15))
            )
        }
    }
}
#endif

extension Notification.Name {
    static let updatePlanStatus = Notification.Name("updatePlanStatus")
}
