//
//  MessageView.swift
//  Chat
//
//  Created by Alex.M on 23.05.2022.
//

import SwiftUI

public enum CustomMessageType : String, Decodable {
    case invite = "invite"
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
    
    var font: UIFont

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
        
        
        VStack{
            if message.type == .system{
                HStack(alignment: .bottom, spacing: 0) {
                    requestAcceptedView(message)
                    
                }
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
                .frame(maxWidth: UIScreen.main.bounds.width, alignment: .center)
            }
            else if message.type == .invite {
                
                HStack(alignment: .bottom, spacing: 0) {
                    
                    avatarView
                    inviteView(message)
                }
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
                .padding(.trailing, message.user.isCurrentUser ? MessageView.horizontalNoAvatarPadding : 0)
                //.padding(message.user.isCurrentUser ? .leading : .trailing, MessageView.horizontalBubblePadding)
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
                    
                    
                    if !message.user.isCurrentUser {
                        avatarView
                    }
                    
                    VStack(alignment: message.user.isCurrentUser ? .trailing : .leading, spacing: 2) {
                        if !isDisplayingMessageMenu, let reply = message.replyMessage?.toMessage() {
                            replyBubbleView(reply)
                                .opacity(0.5)
                                .padding(message.user.isCurrentUser ? .trailing : .leading, 10)
                                .overlay(alignment: message.user.isCurrentUser ? .trailing : .leading) {
                                    Capsule()
                                        .foregroundColor(theme.colors.buttonBackground)
                                        .frame(width: 2)
                                }
                        }
                        bubbleView(message)
                    }
                    
                    if message.user.isCurrentUser, let status = message.status {
                        MessageStatusView(status: status) {
                            if case let .error(draft) = status {
                                viewModel.sendMessage(draft)
                            }
                        }
                        .sizeGetter($statusSize)
                    }
                }
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
                .padding(.trailing, message.user.isCurrentUser ? MessageView.horizontalNoAvatarPadding : 0)
                .padding(message.user.isCurrentUser ? .leading : .trailing, MessageView.horizontalBubblePadding)
                .frame(maxWidth: UIScreen.main.bounds.width, alignment: message.user.isCurrentUser ? .trailing : .leading)
            }
        }.onAppear{
            self.requestStatus = message.requestStatus ?? ""
        }
    }

    @ViewBuilder
    func bubbleView(_ message: Message) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !message.attachments.isEmpty {
                attachmentsView(message)
            }

            if !message.text.isEmpty {
                textWithTimeView(message)
                    .font(Font(font))
            }

            if let recording = message.recording {
                VStack(alignment: .trailing, spacing: 8) {
                    recordingView(recording)
                    messageTimeView()
                        .padding(.bottom, 8)
                        .padding(.trailing, 12)
                }
            }
        }
        .bubbleBackground(message, theme: theme)
    }

    @ViewBuilder
    func replyBubbleView(_ message: Message) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(message.user.name)
                .fontWeight(.semibold)
                .padding(.horizontal, MessageView.horizontalTextPadding)

            if !message.attachments.isEmpty {
                attachmentsView(message)
                    .padding(.top, 4)
                    .padding(.bottom, message.text.isEmpty ? 0 : 4)
            }

            if !message.text.isEmpty {
                MessageTextView(text: message.text, messageUseMarkdown: messageUseMarkdown)
                    .padding(.horizontal, MessageView.horizontalTextPadding)
            }

            if let recording = message.recording {
                recordingView(recording)
            }
        }
        .font(.caption2)
        .padding(.vertical, 8)
        .frame(width: message.attachments.isEmpty ? nil : MessageView.widthWithMedia + additionalMediaInset)
        .bubbleBackground(message, theme: theme, isReply: true)
    }
    
    @ViewBuilder
    func requestAcceptedView(_ message: Message) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(message.text)
                .fontWeight(.semibold)
                .padding(.horizontal, MessageView.horizontalTextPadding)

        }
        .font(.caption2)
        .padding(.vertical, 8)
        .frame(width: message.attachments.isEmpty ? nil : MessageView.widthWithMedia + additionalMediaInset)
    }
    
    
    @ViewBuilder
    func inviteView(_ message: Message) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(message.user.name) would like to invite you")
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
        VStack(alignment: .leading, spacing: 0) {
           

            if !message.attachments.isEmpty {
                attachmentsView(message)
                    .padding(.top, 0)
                    .padding(.bottom, message.text.isEmpty ? 0 : 4)
            }
            if !message.text.isEmpty {
                MessageTextView(text: message.text+" ❤️", messageUseMarkdown: messageUseMarkdown)
                    .padding(.horizontal, MessageView.horizontalTextPadding)
            }
            
        }
        .font(.caption2)
        .padding(.bottom, 8)
        .frame(width: message.attachments.isEmpty ? nil : MessageView.widthWithMedia + additionalMediaInset)
        .bubbleBackground(message, theme: theme, isReply: false)
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
        .overlay(alignment: .bottomTrailing) {
            if message.text.isEmpty {
                messageTimeView(needsCapsule: true)
                    .padding(4)
            }
        }
        .contentShape(Rectangle())
    }

    
    @ViewBuilder
    private func actionButtons(for message: Message) -> some View {
        // Check if the message request status is pending and the user is not the current user
        if (message.requestStatus == "pending" || requestStatus == "pending"), !message.user.isCurrentUser {
            // Check if the request status is neither approved nor rejected to show buttons
            if requestStatus != "approved" && requestStatus != "rejected" {
                VStack(spacing: 10) {
                    Button(action: {
                        // Accept button action
                        if let attendanceGroupId = message.attendanceGroupId,
                           let receiverId = message.receiverId {

                        }
                        if let groupId = message.attachments[0].groupId,
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
                        ZStack {
                            Color.gray.opacity(0.5)
                            Text("Accept")
                                .font(.system(size: 11))
                                .foregroundColor(.black)
                                .bold()
                        }
                    }
                    .frame(height: 25)
                    .clipShape(Capsule())
                    .padding(.horizontal, 0)
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Button(action: {
                        // Reject button action
                        tapActionClosure?(message, "rejected")
                        requestStatus = "rejected" // Update status to hide buttons
                    }) {
                        ZStack {
                            Color.gray.opacity(0.5)
                            Text("Reject")
                                .font(.system(size: 11))
                                .foregroundColor(.black)
                                .bold()
                        }
                    }
                    .frame(height: 25)
                    .clipShape(Capsule())
                    .padding(.horizontal, 0)
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.horizontal, MessageView.horizontalTextPadding)
                .padding(.top, 8)
                .padding(.bottom, 8)
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
            .padding(.trailing, 12)

        Group {
            switch dateArrangement {
            case .hstack:
                HStack(alignment: .lastTextBaseline, spacing: 12) {
                    messageView
                    if !message.attachments.isEmpty {
                        Spacer()
                    }
                    timeView
                }
                .padding(.vertical, 8)
            case .vstack:
                VStack(alignment: .leading, spacing: 4) {
                    messageView
                    HStack(spacing: 0) {
                        Spacer()
                        timeView
                    }
                }
                .padding(.vertical, 8)
            case .overlay:
                messageView
                    .padding(.vertical, 8)
                    .overlay(alignment: .bottomTrailing) {
                        timeView
                            .padding(.vertical, 8)
                    }
            }
        }
    }

    @ViewBuilder
    func recordingView(_ recording: Recording) -> some View {
        RecordWaveformWithButtons(
            recording: recording,
            colorButton: message.user.isCurrentUser ? theme.colors.myMessage : .white,
            colorButtonBg: message.user.isCurrentUser ? .white : theme.colors.myMessage,
            colorWaveform: message.user.isCurrentUser ? theme.colors.textDarkContext : theme.colors.textLightContext
        )
        .padding(.horizontal, MessageView.horizontalTextPadding)
        .padding(.top, 8)
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
        let radius: CGFloat = !message.attachments.isEmpty ? 12 : 20
        let additionalMediaInset: CGFloat = message.attachments.count > 1 ? 2 : 0
        self
            .frame(width: message.attachments.isEmpty ? nil : MessageView.widthWithMedia + additionalMediaInset)
            .foregroundColor(message.user.isCurrentUser ? theme.colors.textDarkContext : theme.colors.textLightContext)
            .background {
                if isReply || !message.text.isEmpty || message.recording != nil {
                    RoundedRectangle(cornerRadius: radius)
                        .foregroundColor(message.user.isCurrentUser ?  Color(hex: "bf9b30") : Color(hex: "d3d3d3"))
                        .opacity(isReply ? 0.5 : 1)
                }
            }
            .cornerRadius(radius)
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
