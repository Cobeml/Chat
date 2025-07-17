//
//  Created by Alex.M on 17.06.2022.
//

import Foundation
import ExyteMediaPicker

public struct DraftMessage {
    public var id: String?
    public let text: String
    public let medias: [Media]
    public let recording: Recording?
    public let replyMessage: ReplyMessage?
    public let createdAt: Date
    public let type: String?
    public let requestStatus: String?
    public let attachMent: Attachment?
    public let receiverId: String?
    public let isGroupInvite: Bool
    public let attendanceGroupId: String?
    public let reelData : ReelModel?
    public let category : String?

    public init(id: String? = nil, 
                text: String,
                medias: [Media],
                recording: Recording?,
                replyMessage: ReplyMessage?,
                createdAt: Date,
                type: String? = nil,
                requestStatus:String? = nil,
                attachMent: Attachment? = nil,
                reelData : ReelModel? = nil,
                receiverId: String? = nil,
                isGroupInvite: Bool = false,
                attendanceGroupId: String? = nil,
                category: String? = nil) {
        self.id = id
        self.text = text
        self.medias = medias
        self.recording = recording
        self.replyMessage = replyMessage
        self.createdAt = createdAt
        self.type = type
        self.requestStatus = requestStatus
        self.attachMent = attachMent
        self.reelData = reelData
        self.receiverId = receiverId
        self.isGroupInvite = isGroupInvite
        self.attendanceGroupId = attendanceGroupId
        self.category = category
    }
}
