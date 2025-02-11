//
//  PlanInviteAttachmentMiniView.swift
//  ExyteChat
//


import SwiftUI

struct PlanInviteAttachmentMiniView: View {
    let onTap: (Attachment) -> Void
    private let attachment: (Attachment)?

    init(attachments: [Attachment], onTap: @escaping (Attachment) -> Void) {
        attachment = attachments.first
        self.onTap = onTap
    }

    var body: some View {
        VStack(spacing: 4) {
            if let attachment = attachment {
                AttachmentCell(attachment: attachment, onTap: onTap)
                    .frame(width: 204, height: 280)
                    .clipped()
                    .cornerRadius(12)
            }
        }
    }
}
