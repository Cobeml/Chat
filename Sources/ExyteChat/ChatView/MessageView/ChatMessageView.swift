//
//  ChatMessageView.swift
//  
//
//  Created by Alisa Mylnikova on 20.03.2023.
//

import SwiftUI

struct ChatMessageView<MessageContent: View>: View {

    typealias MessageBuilderClosure = ChatView<MessageContent, EmptyView, DefaultMessageMenuAction>.MessageBuilderClosure

    @ObservedObject var viewModel: ChatViewModel

    var messageBuilder: MessageBuilderClosure?

    let row: MessageRow
    let chatType: ChatType
    let avatarSize: CGFloat
    let tapAvatarClosure: ChatView.TapAvatarClosure?
    let tapActionClosure: ChatView.TapActionClosure?
    let messageUseMarkdown: Bool
    let isDisplayingMessageMenu: Bool
    let showMessageTimeView: Bool
    let messageFont: UIFont

    var body: some View {
        Group {
            if let messageBuilder = messageBuilder {
                messageBuilder(
                    row.message,
                    row.positionInUserGroup,
                    row.commentsPosition,
                    { viewModel.messageMenuRow = row },
                    viewModel.messageMenuAction()) { attachment in
                        self.viewModel.presentAttachmentFullScreen(attachment)
                    }
            } else {
//                let _ = debugPrint("❌❌❌ \(row.message)")
                MessageView(
                    viewModel: viewModel,
                    message: row.message,
                    positionInUserGroup: row.positionInUserGroup,
                    chatType: chatType,
                    avatarSize: avatarSize,
                    tapAvatarClosure: tapAvatarClosure,
                    tapActionClosure: tapActionClosure,
                    messageUseMarkdown: messageUseMarkdown,
                    isDisplayingMessageMenu: isDisplayingMessageMenu,
                    showMessageTimeView: showMessageTimeView,
                    font: messageFont)
            }
        }
        .id(row.message.id)
    }
}
