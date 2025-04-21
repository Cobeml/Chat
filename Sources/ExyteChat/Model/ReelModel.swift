//
//  ReelModel.swift
//
//
//  Created by Navneet Krishna Ch on 30/03/25.
//

import Foundation
import SwiftUI


// ReelModel ->
// 1) video url (alr stored in firebase)
// 2) venue name
// 3) venue time (set by the sender)
// 4) sender details  (come from the threadModel function)
// 5) AI gen description


public struct ReelModel: Codable, Equatable, Identifiable, Hashable {
    public var id: UUID = UUID()
    public var venueName: String?
    public var venueTime: String?
    public var venuePrice : String?
    public var videoURL: String?
    public var AIdescription: String?
    public var thumbURL : String?

    public init(id: UUID = UUID(),
         venueName: String? = nil,
         venueTime: String? = nil,
         venuePrice : String? = nil,
         videoURL: String? = nil,
         AIdescription: String? = nil,
         thumbURL : String? = nil
    ) {
        self.id = id
        self.venueName = venueName
        self.venueTime = venueTime
        self.venuePrice = venuePrice
        self.videoURL = videoURL
        self.AIdescription = AIdescription
        self.thumbURL = thumbURL
    }
}
