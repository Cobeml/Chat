//
//  ReelModel.swift
//
//
//  Created by Navneet Krishna Ch on 30/03/25.
//

import Foundation
import SwiftUI

// ReelModel ->
// 1) video url (already stored in firebase)
// 2) venue name
// 3) venue time (set by the sender)
// 4) sender details (come from the threadModel function)
// 5) AI generated description

public enum VideoType: String, CaseIterable, Codable {
    case youtube = "youtube"
    case normal = "normal"
    case tiktok = "tiktok"
    
    var iconName: String {
        switch self {
        case .youtube: return "play.rectangle.fill" // or "video.fill"
        case .normal: return "video.fill"
        case .tiktok: return "music.note" // or "video.badge.plus"
        }
    }
}

public struct ReelModel: Codable, Equatable, Identifiable, Hashable {
    public var id: UUID = UUID()
    public var venueName: String?
    public var venueTime: String?
    public var venuePrice: String?
    public var videoURL: String?
    public var aiDescription: String? // Fixed naming convention
    public var thumbURL: String?
    public var videoType: VideoType = .normal
    public var venueId: String?
    
    // Optional: Add sender details as mentioned in comments
    public var senderID: String?
    public var senderName: String?
    public var category: String?

    public init(
        id: UUID = UUID(),
        venueName: String? = nil,
        venueTime: String? = nil,
        venuePrice: String? = nil,
        videoURL: String? = nil,
        aiDescription: String? = nil, // Fixed parameter name
        thumbURL: String? = nil,
        videoType: VideoType = .normal, // Added default value
        senderID: String? = nil,
        senderName: String? = nil,
        venueId: String? = nil,
        category: String? = nil
    ) {
        self.id = id
        self.venueName = venueName
        self.venueTime = venueTime
        self.venuePrice = venuePrice
        self.videoURL = videoURL
        self.aiDescription = aiDescription
        self.thumbURL = thumbURL
        self.videoType = videoType
        self.senderID = senderID
        self.senderName = senderName
        self.venueId = venueId
        self.category = category
    }
}
