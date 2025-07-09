//
//  MessageView.swift
//  Chat
//
//  Created by Alex.M on 23.05.2022.
//

import SwiftUI
import AVKit


struct YouTubeUtility {
    static func extractVideoId(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        
        let host = url.host?.lowercased()
        
        if host == "youtu.be" {
            // Format: https://youtu.be/VIDEO_ID
            return String(url.path.dropFirst()) // Remove leading "/"
        } else if host == "www.youtube.com" || host == "youtube.com" || host == "m.youtube.com" {
            // Handle different YouTube URL formats
            
            if url.path.contains("/watch") {
                // Format: https://www.youtube.com/watch?v=VIDEO_ID
                return URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?
                    .first(where: { $0.name == "v" })?
                    .value
            } else if url.path.contains("/embed/") {
                // Format: https://www.youtube.com/embed/VIDEO_ID
                let pathComponents = url.path.components(separatedBy: "/")
                if let embedIndex = pathComponents.firstIndex(of: "embed"),
                   embedIndex + 1 < pathComponents.count {
                    return pathComponents[embedIndex + 1]
                }
            } else if url.path.contains("/v/") {
                // Format: https://www.youtube.com/v/VIDEO_ID
                let pathComponents = url.path.components(separatedBy: "/")
                if let vIndex = pathComponents.firstIndex(of: "v"),
                   vIndex + 1 < pathComponents.count {
                    return pathComponents[vIndex + 1]
                }
            } else if url.path.contains("/shorts/") {
                // Format: https://www.youtube.com/shorts/VIDEO_ID
                // Format: https://youtube.com/shorts/VIDEO_ID
                // Format: https://m.youtube.com/shorts/VIDEO_ID
                let pathComponents = url.path.components(separatedBy: "/")
                if let shortsIndex = pathComponents.firstIndex(of: "shorts"),
                   shortsIndex + 1 < pathComponents.count {
                    let videoId = pathComponents[shortsIndex + 1]
                    // Remove any query parameters that might be attached
                    return videoId.components(separatedBy: "?").first
                }
            }
        }
        
        return nil
    }
    
    static func getThumbnailURL(for videoId: String) -> URL? {
        let baseURL = "https://img.youtube.com/vi/\(videoId)/sddefault.jpg"
        return URL(string: baseURL)
    }
    
    static func isYouTubeURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        let host = url.host?.lowercased()
        
        return host == "youtu.be" ||
               host == "www.youtube.com" ||
               host == "youtube.com" ||
               host == "m.youtube.com"
    }
    
    // Helper function to detect if URL is specifically a YouTube Short
    static func isYouTubeShort(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.path.contains("/shorts/")
    }
}


public enum CustomMessageType : String, Decodable {
    case invite = "invite"
    case friendInvite = "friendinvite"
    case planInvite = "planInvite"
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
                    if hasYouTubeShortsURL(message) {
                                           // Show YouTube Shorts preview with accept/reject buttons
                                           youTubeShortsInviteView(message)
                                       } else {
                                           // Show regular join view with attachments
                                           regularJoinView(message)
                                       }
                    }
                    .padding(.top, topPadding + 8)
                    .padding(.bottom, bottomPadding + 8)
                    .padding(.trailing, message.user.isCurrentUser ? MessageView.horizontalNoAvatarPadding : 0)
                    .padding(message.user.isCurrentUser ? .trailing : .leading, 10)
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
                    
                    UserAvatarView(avatarURL: message.user.avatarURL, name: message.user.name, size: 40)
                    
                    
                    
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

        var receiverName: String = "Daniel"
        let receiverAge: String = "103"
        let avatarURL : URL?
      
        let cropWidth: CGFloat = 170
        let cropHeight: CGFloat = 250

        init(message: Message) {
            self.message = message
            self.location = message.venueName ?? ""
            self.time = message.venueTime ?? ""
            self.price = message.venuePrice ?? ""
            self.description = message.AIdescription ?? ""
            self.receiverName = message.user.name
            self.avatarURL = message.user.avatarURL
           
            if let firstAttachment = message.attachments.first {
                self._player = State(initialValue: AVPlayer(url: firstAttachment.full))
            } else {
                self._player = State(initialValue: AVPlayer())  // Fallback to empty player
            }
        }
        
        private func getThumbnailURL(for message: Message) -> URL? {
             if let firstAttachment = message.attachments.first {
                 let videoURLString = firstAttachment.full.absoluteString
                 
                 if YouTubeUtility.isYouTubeURL(videoURLString) {
                     if let videoId = YouTubeUtility.extractVideoId(from: videoURLString) {
                         return YouTubeUtility.getThumbnailURL(for: videoId)
                     }
                 } else {
                     return firstAttachment.full
                 }
             }
             
             return message.attachments.first?.thumbnail
         }
         
                
        var body: some View {
                VStack(alignment: .center){
                    Button(action: { showReelInvite = true }) {
                        ZStack {
                            ReelThumbnailDisplay(message:  message, crop_width: cropWidth, crop_height: cropHeight, isThumbnailLoaded : $isThumbnailLoaded)

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
                                        InviterInfoDisplay(DpRadius: 40, message: message, Description: description)
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
        
        private func ReelThumbnailDisplay(message: Message, crop_width: CGFloat, crop_height: CGFloat, isThumbnailLoaded: Binding<Bool>) -> some View {
            Group {
                let thumbnailURL = determineThumbnailURL(for: message)
                
                if let validURL = thumbnailURL {
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
                    }
                    .onAppear {
                        isThumbnailLoaded.wrappedValue = false
                    }
                }
            }
        }
        
        private func determineThumbnailURL(for message: Message) -> URL? {
               // First, check if there's a video URL in the message attachments
               if let firstAttachment = message.attachments.first {
                   let videoURLString = firstAttachment.full.absoluteString
                   
                   // Check if it's a YouTube URL
                   if YouTubeUtility.isYouTubeURL(videoURLString) {
                       // Extract video ID and create YouTube thumbnail URL
                       if let videoId = YouTubeUtility.extractVideoId(from: videoURLString) {
                           return YouTubeUtility.getThumbnailURL(for: videoId)
                       }
                   } else {
                       // For non-YouTube videos, use the original video URL as thumbnail
                       // This might work for some video services that serve thumbnails directly
                       return firstAttachment.full
                   }
               }
               
               // Fallback: use the thumbnail URL from attachments if available
               return message.attachments.first?.thumbnail
           }
        
        private func InviterInfoDisplay(DpRadius : CGFloat, message: Message, Description : String) -> some View {
            Button {} label: {
                UserAvatarView(avatarURL: message.user.avatarURL, name: message.user.name, size: 40)
            
            
                VStack(alignment: .center, spacing: 2) {
                    HStack {
                        Text(message.user.name)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .padding(.leading, -5)
                        
                        Text("")
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



import SwiftUI

import WebKit

// MARK: - Full Screen YouTube Modal
struct YouTubeFullScreenModal: View {
    @Environment(\.dismiss) var dismiss
    let videoID: String
    let videoTitle: String
    let originalURL: String
    
    @State private var isLoading = true
    @State private var showingShareSheet = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Navigation Header
                NavigationHeader(
                    title: videoTitle,
                    onBack: { dismiss() },
                    onShare: { showingShareSheet = true }
                )
                
                // Main Video Player
                VideoPlayerContainer(
                    videoID: videoID,
                    isLoading: $isLoading
                )
                
                // Loading Overlay
                if isLoading {
                    VideoLoadingOverlay()
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [originalURL])
        }
    }
}

// MARK: - Navigation Header Component
struct NavigationHeader: View {
    let title: String
    let onBack: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack {
            // Back Button
            BackButton(action: onBack)
            
            Spacer()
            
            // Title
            VideoTitle(title: title)
            
            Spacer()
            
            // Share Button
            ShareButton(action: onShare)
        }
        .padding(.top, 50) // Safe area compensation
        .padding(.bottom, 20)
        .padding(.horizontal, 20)
        .background(headerBackground)
    }
    
    private var headerBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black.opacity(0.95),
                Color.black.opacity(0.8),
                Color.clear
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Back Button Component
struct BackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Video Title Component
struct VideoTitle: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}

// MARK: - Share Button Component
struct ShareButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Video Player Container
struct VideoPlayerContainer: View {
    let videoID: String
    @Binding var isLoading: Bool
    
    var body: some View {
        GeometryReader { geometry in
            SimpleYouTubePlayerView(videoID: videoID, isLoading: $isLoading)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 0))
        }
    }
}

// MARK: - Video Loading Overlay
struct VideoLoadingOverlay: View {
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            // Loading content
            VStack(spacing: 20) {
                // Animated loading spinner
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2.0)
                
                // Loading text
                Text("Loading video...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                // YouTube branding
                HStack(spacing: 8) {
                    Image(systemName: "play.rectangle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                    
                    Text("YouTube")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 10)
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Updated YouTube Shorts Content View
struct YouTubeShortsContentView: View {
    let message: Message
    @Binding var requestStatus: String
    let onAccept: () -> Void
    let onReject: () -> Void
    
    @State private var showFullScreen = false
    @State private var videoTitle: String = "Video Invitation"
    @State private var extractedThumbnail: String = ""
    @State private var videoID: String = ""
    
    var body: some View {
        VStack(spacing: 12) {
            if let attachment = message.attachments.first {
                YouTubeShortsPreviewCard(
                    youtubeURL: attachment.full.absoluteString,
                    thumbnailURL: extractedThumbnail.isEmpty ? attachment.thumbnail.absoluteString : extractedThumbnail,
                    videoTitle: videoTitle,
                    onTap: { showFullScreen = true }
                )
                .padding(.horizontal, 12)
                
                if shouldShowButtons {
                    AcceptRejectButtonsView(
                        onAccept: onAccept,
                        onReject: onReject
                    )
                }
            }
        }
        .sheet(isPresented: $showFullScreen) {
            SimpleYouTubePlayerView(videoID: videoID)
        }
        .onAppear {
            extractVideoInfo()
        }
    }
    
    private var shouldShowButtons: Bool {
        let isPending = message.requestStatus == "pending" || requestStatus == "pending"
        let isNotCurrentUser = !message.user.isCurrentUser
        let isNotProcessed = requestStatus != "approved" && requestStatus != "rejected"
        
        return isPending && isNotCurrentUser && isNotProcessed
    }
    
    private func extractVideoInfo() {
        guard let attachment = message.attachments.first,
              let extractedVideoID = extractVideoId(from: attachment.full.absoluteString) else {
            return
        }
        
        videoID = extractedVideoID
        extractedThumbnail = "https://img.youtube.com/vi/\(extractedVideoID)/maxresdefault.jpg"
        
        // Set a better title if available
        if let venueName = message.venueName, !venueName.isEmpty {
            videoTitle = "\(message.user.name) invites you to \(venueName)"
        } else {
            videoTitle = "\(message.user.name)'s Video Invitation"
        }
    }
    
    private func extractVideoId(from url: String) -> String? {
        if let range = url.range(of: "shorts/") {
            let afterShorts = String(url[range.upperBound...])
            if let queryRange = afterShorts.range(of: "?") {
                return String(afterShorts[..<queryRange.lowerBound])
            }
            return afterShorts
        }
        return nil
    }
}

// MARK: - Alternative Compact Full Screen Modal (if you prefer simpler)
struct CompactYouTubeModal: View {
    @Environment(\.dismiss) var dismiss
    let videoID: String
    let videoTitle: String
    
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Simple header
                HStack {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                        .padding()
                    
                    Spacer()
                    
                    Text(videoTitle)
                        .foregroundColor(.white)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 60) // Balance the Done button
                }
                .background(Color.black.opacity(0.8))
                
                // Video player
                SimpleYouTubePlayerView(videoID: videoID, isLoading: $isLoading)
                
                if isLoading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Loading...")
                            .foregroundColor(.white)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.8))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}


struct SimpleYouTubePlayerView: UIViewRepresentable {
    let videoID: String
    @Binding var isLoading: Bool
    
    init(videoID: String, isLoading: Binding<Bool> = .constant(false)) {
        self.videoID = videoID
        self._isLoading = isLoading
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.navigationDelegate = context.coordinator
        
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1"
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.youtube.com"
        components.path = "/embed/\(videoID)"
        components.queryItems = [
            URLQueryItem(name: "autoplay", value: "1"),
            URLQueryItem(name: "playsinline", value: "1"),
            URLQueryItem(name: "controls", value: "0"),
            URLQueryItem(name: "showinfo", value: "0"),
            URLQueryItem(name: "rel", value: "0"),
            URLQueryItem(name: "mute", value: "1"),
            URLQueryItem(name: "origin", value: "https://www.youtube.com")
        ]
        
        guard let embedURL = components.url else {
            return
        }
        
        var request = URLRequest(url: embedURL)
        request.setValue("https://www.youtube.com", forHTTPHeaderField: "Referer")
        request.setValue("no-referrer-when-downgrade", forHTTPHeaderField: "Referrer-Policy")
        
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: SimpleYouTubePlayerView
        
        init(_ parent: SimpleYouTubePlayerView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

// MARK: - Simple Invite Header Component
struct InviteHeaderView: View {
    let message: Message
    
    var body: some View {
        HStack(spacing: 8) {
            UserAvatarView(avatarURL: message.user.avatarURL, name: message.user.name, size: 40)
            
            InviteTextView(message: message)
            
            Spacer()
            
            InviteIconView()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

// MARK: - User Avatar Component
struct UserAvatarView: View {
    let avatarURL: URL?
    let name: String
    let size: CGFloat
    let strokeWidth: CGFloat
    let strokeColor: Color
    
    init(
        avatarURL: URL?,
        name: String,
        size: CGFloat = 80,
        strokeWidth: CGFloat = 2,
        strokeColor: Color = .white
    ) {
        self.avatarURL = avatarURL
        self.name = name
        self.size = size
        self.strokeWidth = strokeWidth
        self.strokeColor = strokeColor
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: size, height: size)
            
            // Profile Image or Initials
            if let avatarURL = avatarURL {
                AsyncImage(url: avatarURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size - strokeWidth * 2, height: size - strokeWidth * 2)
                            .clipShape(Circle())
                    case .failure(_):
                        InitialsView(name: name, size: size - strokeWidth * 2)
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: size - strokeWidth * 2, height: size - strokeWidth * 2)
                    @unknown default:
                        InitialsView(name: name, size: size - strokeWidth * 2)
                    }
                }
            } else {
                InitialsView(name: name, size: size - strokeWidth * 2)
            }
        }
        .overlay(
            Circle()
                .stroke(strokeColor, lineWidth: strokeWidth)
                .frame(width: size, height: size)
        )
    }
}

struct InitialsView: View {
    let name: String
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.7),
                        Color.purple.opacity(0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)
            
            Text(initials)
                .font(.system(size: size * 0.3, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private var initials: String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            let firstInitial = String(words[0].prefix(1))
            let lastInitial = String(words[1].prefix(1))
            return "\(firstInitial)\(lastInitial)".uppercased()
        } else if let firstWord = words.first {
            return String(firstWord.prefix(1)).uppercased()
        }
        return "U"
    }
}


// MARK: - Invite Text Component
struct InviteTextView: View {
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(message.user.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(inviteTypeText)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            if let venueName = message.venueName, !venueName.isEmpty {
                Text(venueName)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "e8b717"))
                    .fontWeight(.medium)
            }
        }
    }
    
    private var inviteTypeText: String {
        switch message.type {
        case .invite:
            return "sent an invite"
        case .planInvite:
            return "invites you to"
        case .join:
            return "wants you to join"
        default:
            return "shared a video"
        }
    }
}

// MARK: - Invite Icon Component
struct InviteIconView: View {
    var body: some View {
        Image(systemName: "video.circle")
            .foregroundColor(Color(hex: "e8b717"))
            .font(.title2)
    }
}

// MARK: - YouTube Thumbnail Component
struct YouTubeThumbnailView: View {
    let thumbnailURL: String?
    let cropWidth: CGFloat
    let cropHeight: CGFloat
    
    var body: some View {
        Group {
            if let urlString = thumbnailURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        thumbnailImageView(image)
                    case .failure(_):
                        fallbackView
                    case .empty:
                        loadingView
                    @unknown default:
                        fallbackView
                    }
                }
            } else {
                fallbackView
            }
        }
    }
    
    private func thumbnailImageView(_ image: Image) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: cropWidth, height: cropHeight)
            .clipped()
    }
    
    private var loadingView: some View {
        ZStack {
            Color.gray.opacity(0.3)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
        .frame(width: cropWidth, height: cropHeight)
    }
    
    private var fallbackView: some View {
        YouTubeFallbackView(width: cropWidth, height: cropHeight)
    }
}

// MARK: - YouTube Fallback Component
struct YouTubeFallbackView: View {
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack {
            backgroundGradient
            contentView
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.red.opacity(0.8),
                Color.red.opacity(0.4),
                Color.black
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: width, height: height)
    }
    
    private var contentView: some View {
        VStack(spacing: 12) {
            Image(systemName: "play.rectangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.white)
            
            VStack(spacing: 4) {
                Text("YouTube")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Shorts")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Video Overlay Component
struct VideoOverlayView: View {
    let videoTitle: String
    
    var body: some View {
        VStack {
            shortsBadge
            Spacer()
            playButton
            Spacer()
            titleSection
        }
    }
    
    private var shortsBadge: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "play.rectangle.fill")
                    .foregroundColor(.white)
                    .font(.caption)
                Text("Shorts")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(8)
            .background(Color.black.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.top, 12)
            .padding(.trailing, 12)
        }
    }
    
    private var playButton: some View {
        Image(systemName: "play.circle.fill")
            .foregroundColor(.white)
            .font(.system(size: 60))
            .shadow(color: .black.opacity(0.5), radius: 15)
    }
    
    private var titleSection: some View {
        VStack(spacing: 8) {
            if !videoTitle.isEmpty {
                Text(videoTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 16)
            }
            
            Text("Tap to watch")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 16)
        .background(titleBackground)
    }
    
    private var titleBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [.clear, .black.opacity(0.9)]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Accept/Reject Buttons Component
struct AcceptRejectButtonsView: View {
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            rejectButton
            acceptButton
        }
        .padding(.horizontal, 8)
    }
    
    private var rejectButton: some View {
        Button(action: onReject) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 16, weight: .medium))
                Text("Decline")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(rejectButtonBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var rejectButtonBackground: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(Color.red.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.red.opacity(0.6), lineWidth: 1.5)
            )
    }
    
    private var acceptButton: some View {
        Button(action: onAccept) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                Text("Accept")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(acceptButtonBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var acceptButtonBackground: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(Color(hex: "e8b717"))
    }
}

// MARK: - Status Indicator Component
struct StatusIndicatorView: View {
    let requestStatus: String
    
    var body: some View {
        HStack(spacing: 8) {
            statusIcon
            statusText
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private var statusIcon: some View {
        Image(systemName: requestStatus == "approved" ? "checkmark.circle.fill" : "xmark.circle.fill")
            .foregroundColor(requestStatus == "approved" ? .green : .red)
            .font(.system(size: 16))
    }
    
    private var statusText: some View {
        Text(requestStatus == "approved" ? "Invitation Accepted" : "Invitation Declined")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(requestStatus == "approved" ? .green : .red)
    }
}

// MARK: - Venue Details Component
struct VenueDetailsView: View {
    let venueTime: String?
    let venuePrice: String?
    
    var body: some View {
        if let time = venueTime, !time.isEmpty,
           let price = venuePrice, !price.isEmpty {
            HStack {
                timeSection(time)
                Spacer()
                priceSection(price)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            .padding(.horizontal, 16)
        }
    }
    
    private func timeSection(_ time: String) -> some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.gray)
                .font(.caption)
            Text(time)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
    
    private func priceSection(_ price: String) -> some View {
        HStack {
            Image(systemName: "dollarsign.circle")
                .foregroundColor(.gray)
                .font(.caption)
            Text(price)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Main Video Preview Component
struct YouTubeShortsPreviewCard: View {
    let youtubeURL: String
    let thumbnailURL: String?
    let videoTitle: String
    let onTap: () -> Void
    
    private let cropWidth: CGFloat = 200
    private let cropHeight: CGFloat = 350
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                YouTubeThumbnailView(
                    thumbnailURL: thumbnailURL,
                    cropWidth: cropWidth,
                    cropHeight: cropHeight
                )
                
                VideoOverlayView(videoTitle: videoTitle)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: cropWidth, height: cropHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Main YouTube Shorts Invite View
extension MessageView {
    
    @ViewBuilder
      func simpleYouTubeShortsInviteView(_ message: Message) -> some View {
          SimpleYouTubeShortsInviteView(
              message: message,
              requestStatus: $requestStatus,
              onAccept: { handleAcceptAction(for: message) },
              onReject: { handleRejectAction(for: message) }
          )
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
      }
    
    @ViewBuilder
    func youTubeShortsInviteView(_ message: Message) -> some View {
        VStack(spacing: 12) {
            InviteHeaderView(message: message)
            
            YouTubeShortsContentView(
                message: message,
                requestStatus: $requestStatus,
                onAccept: { handleAcceptAction(for: message) },
                onReject: { handleRejectAction(for: message) }
            )
            
            if !message.text.isEmpty {
                MessageTextSection(text: message.text)
            }
            
            VenueDetailsView(
                venueTime: message.venueTime,
                venuePrice: message.venuePrice
            )
            
            if requestStatus == "approved" || requestStatus == "rejected" {
                StatusIndicatorView(requestStatus: requestStatus)
            }
        }
        .background(inviteBackground)
        .opacity(requestStatus == "approved" || requestStatus == "rejected" ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: requestStatus)
        .padding(.trailing, 20)
    }
    
    private var inviteBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(hex: "1a1a1a"))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1.5)
            )
    }
    
    private var borderColor: Color {
        switch requestStatus {
        case "approved":
            return Color.green.opacity(0.5)
        case "rejected":
            return Color.red.opacity(0.5)
        default:
            return Color(hex: "e8b717").opacity(0.4)
        }
    }
    
    private func handleAcceptAction(for message: Message) {
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
                    print("✅ Video invite accepted: \(response.message)")
                case .failure(let error):
                    print("❌ Failed to accept video invite: \(error.localizedDescription)")
                }
            }
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            requestStatus = "approved"
        }
        tapActionClosure?(message, "approved")
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func handleRejectAction(for message: Message) {
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
        
        withAnimation(.easeInOut(duration: 0.3)) {
            requestStatus = "rejected"
        }
        tapActionClosure?(message, "rejected")
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    
    struct SimpleYouTubeShortsInviteView: View {
        let message: Message
        @Binding var requestStatus: String
        let onAccept: () -> Void
        let onReject: () -> Void
        
        @State private var showFullScreen = false
        @State private var videoTitle: String = ""
        @State private var videoID: String = ""
        
        private let cardWidth: CGFloat = 180
        private let cardHeight: CGFloat = 280
        
        var body: some View {
            VStack(spacing: 16) {
                // Header
                simpleHeader
                
                // Video Card
                simpleVideoCard
                
                // Message Text
                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                // Action Buttons or Status
                if requestStatus == "approved" || requestStatus == "rejected" {
                    statusView
                } else if shouldShowButtons {
                    actionButtons
                }
            }
            .padding(16)
            .background(Color(hex: "1a1a1a"))
            .cornerRadius(12)
            .sheet(isPresented: $showFullScreen) {
                SimpleYouTubePlayerModal(videoID: videoID, videoTitle: videoTitle)
            }
            .onAppear {
                extractVideoInfo()
            }
        }
        
        // MARK: - Header
        private var simpleHeader: some View {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.gray)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(message.user.name.prefix(1)))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                // User info
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.user.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("sent a video invite")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // YouTube icon
                Image(systemName: "play.rectangle")
                    .foregroundColor(.red)
                    .font(.title2)
            }
        }
        
        // MARK: - Video Card
        private var simpleVideoCard: some View {
            Button(action: { showFullScreen = true }) {
                ZStack {
                    // Thumbnail
                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: cardWidth, height: cardHeight)
                                .clipped()
                        case .failure(_), .empty:
                            placeholderView
                        @unknown default:
                            placeholderView
                        }
                    }
                    
                    // Dark overlay
                    Color.black.opacity(0.3)
                    
                    // Play button
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    
                    // Video info overlay
                    VStack {
                        Spacer()
                        
                        if !videoTitle.isEmpty {
                            Text(videoTitle)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                                .padding(.bottom, 12)
                        }
                    }
                    
                    // Shorts badge
                    VStack {
                        HStack {
                            Spacer()
                            Text("Shorts")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                                .padding(.top, 12)
                                .padding(.trailing, 12)
                        }
                        Spacer()
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: cardWidth, height: cardHeight)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        
        private var placeholderView: some View {
            ZStack {
                Color.gray.opacity(0.3)
                    .frame(width: cardWidth, height: cardHeight)
                
                VStack(spacing: 8) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    
                    Text("YouTube\nShorts")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            }
        }
        
        // MARK: - Action Buttons
        private var actionButtons: some View {
            HStack(spacing: 12) {
                // Decline
                Button(action: onReject) {
                    Text("Decline")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
                
                // Accept
                Button(action: onAccept) {
                    Text("Accept")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
        }
        
        // MARK: - Status View
        private var statusView: some View {
            HStack(spacing: 8) {
                Image(systemName: requestStatus == "approved" ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(requestStatus == "approved" ? .green : .red)
                
                Text(requestStatus == "approved" ? "Accepted" : "Declined")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(requestStatus == "approved" ? .green : .red)
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        
        // MARK: - Computed Properties
        private var shouldShowButtons: Bool {
            let isPending = message.requestStatus == "pending" || requestStatus == "pending"
            let isNotCurrentUser = !message.user.isCurrentUser
            let isNotProcessed = requestStatus != "approved" && requestStatus != "rejected"
            
            return isPending && isNotCurrentUser && isNotProcessed
        }
        
        private var thumbnailURL: URL? {
            if !videoID.isEmpty {
                return URL(string: "https://img.youtube.com/vi/\(videoID)/maxresdefault.jpg")
            }
            return message.attachments.first?.thumbnail
        }
        
        // MARK: - Helper Methods
        private func extractVideoInfo() {
            guard let attachment = message.attachments.first,
                  let extractedVideoID = extractVideoId(from: attachment.full.absoluteString) else {
                return
            }
            
            videoID = extractedVideoID
            
            if let venueName = message.venueName, !venueName.isEmpty {
                videoTitle = "Invite to \(venueName)"
            } else {
                videoTitle = "Video Invitation"
            }
        }
        
        private func extractVideoId(from url: String) -> String? {
            if let range = url.range(of: "shorts/") {
                let afterShorts = String(url[range.upperBound...])
                if let queryRange = afterShorts.range(of: "?") {
                    return String(afterShorts[..<queryRange.lowerBound])
                }
                return afterShorts
            }
            return nil
        }
    }

    // MARK: - Simple YouTube Player Modal
    struct SimpleYouTubePlayerModal: View {
        @Environment(\.dismiss) var dismiss
        let videoID: String
        let videoTitle: String
        
        @State private var isLoading = true
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding()
                        
                        Spacer()
                        
                        Text(videoTitle)
                            .foregroundColor(.white)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Spacer for balance
                        Color.clear.frame(width: 60)
                    }
                    .background(Color.black)
                    
                    // Video Player
                    SimpleYouTubePlayerView(videoID: videoID, isLoading: $isLoading)
                    
                    // Loading overlay
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Loading video...")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.8))
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Simple YouTube Player View
    struct SimpleYouTubePlayerView: UIViewRepresentable {
        let videoID: String
        @Binding var isLoading: Bool
        
        func makeUIView(context: Context) -> WKWebView {
            let configuration = WKWebViewConfiguration()
            configuration.allowsInlineMediaPlayback = true
           // configuration.mediaTypesRequiringUserActionForPlayboot = []
            
            let webView = WKWebView(frame: .zero, configuration: configuration)
            webView.scrollView.isScrollEnabled = false
            webView.backgroundColor = .black
            webView.navigationDelegate = context.coordinator
            
            return webView
        }
        
        func updateUIView(_ webView: WKWebView, context: Context) {
            let embedURL = "https://www.youtube.com/embed/\(videoID)?autoplay=1&playsinline=1&controls=1&rel=0"
            
            if let url = URL(string: embedURL) {
                let request = URLRequest(url: url)
                webView.load(request)
            }
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, WKNavigationDelegate {
            var parent: SimpleYouTubePlayerView
            
            init(_ parent: SimpleYouTubePlayerView) {
                self.parent = parent
            }
            
            func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
                parent.isLoading = true
            }
            
            func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.parent.isLoading = false
                }
            }
            
            func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
                parent.isLoading = false
            }
        }
    }

}

// MARK: - Message Text Section
struct MessageTextSection: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.9))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
    }
}



extension MessageView {
    
    @ViewBuilder
    func regularJoinView(_ message: Message) -> some View {
        VStack(spacing: 12) {
            // Header Section
            HStack(spacing: 8) {
                // User Avatar
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(message.user.name.prefix(1)))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(message.user.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("wants to join")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    if let venueName = message.venueName, !venueName.isEmpty {
                        Text(venueName)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "e8b717"))
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                Image(systemName: "person.crop.circle.badge.plus")
                    .foregroundColor(Color(hex: "e8b717"))
                    .font(.title2)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Content Section with Regular Attachments
            VStack(spacing: 8) {
                // Regular Attachments (Images, Documents, etc.)
                if !message.attachments.isEmpty {
                    attachmentsView(message)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                }
                
                // Message text
                if !message.text.isEmpty {
                    HStack {
                        Text(message.text)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 16)
                        Spacer()
                    }
                }
                
                // Venue details
                if let venueTime = message.venueTime, !venueTime.isEmpty,
                   let venuePrice = message.venuePrice, !venuePrice.isEmpty {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Text(venueTime)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Image(systemName: "dollarsign.circle")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Text(venuePrice)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                }
            }
            
            // Accept/Reject Buttons for Regular Join
            regularJoinActionButtons(for: message)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1a1a1a"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor, lineWidth: 1.5)
                )
        )
        .opacity(requestStatus == "approved" || requestStatus == "rejected" ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: requestStatus)
    }
    
    @ViewBuilder
    private func regularJoinActionButtons(for message: Message) -> some View {
        let isApprovedOrRejected = requestStatus == "approved" || requestStatus == "rejected"
        let isPending = message.requestStatus == "pending" || requestStatus == "pending"
        
        if isPending && !message.user.isCurrentUser && !isApprovedOrRejected {
            // Active buttons for pending requests
            HStack(spacing: 12) {
                // Reject Button
                Button(action: {
                    handleRejectAction(for: message)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 14, weight: .medium))
                        Text("Decline")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.red.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Accept Button
                Button(action: {
                    handleAcceptAction(for: message)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("Accept")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(hex: "e8b717"))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        } else if isApprovedOrRejected {
            // Status indicator for completed requests
            HStack(spacing: 8) {
                Image(systemName: requestStatus == "approved" ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(requestStatus == "approved" ? .green : .red)
                    .font(.system(size: 16))
                
                Text(requestStatus == "approved" ? "Request Accepted" : "Request Declined")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(requestStatus == "approved" ? .green : .red)
                
                Spacer()
                
                Text(message.time)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
        } else if message.user.isCurrentUser {
            // Status for sender
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.gray)
                    .font(.caption)
                
                Text("Join request sent")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(message.time)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
        }
    }
}

private func hasYouTubeShortsURL(_ message: Message) -> Bool {
       // Check in attachments
    
       if message.attachments.contains(where: { attachment in
           attachment.full.absoluteString.contains("youtube.com/shorts/") ||
           attachment.full.absoluteString.contains("youtu.be/") // Also check for short URLs
       }) {
           return true
       }
       
       // Check in message text as backup
       if message.text.contains("youtube.com/shorts/") || message.text.contains("youtu.be/") {
           return true
       }
       
       return false
   }
   


