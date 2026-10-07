//
//  LiveSession.swift
//  My Pet
//
//  Created by Richard Balabarcon on 07/10/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct LiveSession: Identifiable, Codable {

    var id: String?

    var hostId: String
    var hostUsername: String
    var hostProfileImageURL: String?

    var title: String

    var status: String

    @ServerTimestamp
    var startedAt: Date?

    var endedAt: Date?

    var viewerCount: Int

    var streamId: String?

    init(
        id: String? = nil,
        hostId: String,
        hostUsername: String,
        hostProfileImageURL: String? = nil,
        title: String = "",
        status: String = "live",
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        viewerCount: Int = 0,
        streamId: String? = nil
    ) {
        self.id = id
        self.hostId = hostId
        self.hostUsername = hostUsername
        self.hostProfileImageURL = hostProfileImageURL
        self.title = title
        self.status = status
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.viewerCount = viewerCount
        self.streamId = streamId
    }

    enum CodingKeys: String, CodingKey {
        case id
        case hostId
        case hostUsername
        case hostProfileImageURL
        case title
        case status
        case startedAt
        case endedAt
        case viewerCount
        case streamId
    }

    init(from decoder: Decoder) throws {

        let container =
            try decoder.container(
                keyedBy: CodingKeys.self
            )

        self.id =
            try container.decodeIfPresent(
                String.self,
                forKey: .id
            )

        self.hostId =
            try container.decode(
                String.self,
                forKey: .hostId
            )

        self.hostUsername =
            try container.decodeIfPresent(
                String.self,
                forKey: .hostUsername
            ) ?? "Unknown"

        self.hostProfileImageURL =
            try container.decodeIfPresent(
                String.self,
                forKey: .hostProfileImageURL
            )

        self.title =
            try container.decodeIfPresent(
                String.self,
                forKey: .title
            ) ?? ""

        self.status =
            try container.decodeIfPresent(
                String.self,
                forKey: .status
            ) ?? "live"

        self.startedAt =
            try container.decodeIfPresent(
                Date.self,
                forKey: .startedAt
            )

        self.endedAt =
            try container.decodeIfPresent(
                Date.self,
                forKey: .endedAt
            )

        self.viewerCount =
            try container.decodeIfPresent(
                Int.self,
                forKey: .viewerCount
            ) ?? 0

        self.streamId =
            try container.decodeIfPresent(
                String.self,
                forKey: .streamId
            )
    }
}
