import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct Post: Identifiable, Codable {
    var id: String?
    var caption: String

    // Existing single-image field
    var imageURL: String?

    // New: supports up to 10 images
    var imageURLs: [String]

    var mediaType: String?
    var ownerId: String

    @ServerTimestamp var createdAt: Date?

    var likes: Int
    var reposts: Int
    var shares: Int
    var comments: Int

    var user: UserModel? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case caption
        case imageURL
        case imageURLs
        case mediaType
        case ownerId
        case createdAt
        case likes
        case reposts
        case shares
        case comments
    }

    init(
        id: String? = nil,
        caption: String,
        imageURL: String? = nil,
        imageURLs: [String] = [],
        mediaType: String? = nil,
        ownerId: String,
        createdAt: Date? = nil,
        likes: Int = 0,
        reposts: Int = 0,
        comments: Int = 0,
        shares: Int = 0,
        user: UserModel? = nil
    ) {
        self.id = id
        self.caption = caption
        self.imageURL = imageURL
        self.imageURLs = imageURLs
        self.mediaType = mediaType
        self.ownerId = ownerId
        self.createdAt = createdAt
        self.likes = likes
        self.reposts = reposts
        self.shares = shares
        self.comments = comments
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id =
            try container.decodeIfPresent(
                String.self,
                forKey: .id
            )

        self.caption =
            try container.decodeIfPresent(
                String.self,
                forKey: .caption
            ) ?? ""

        self.imageURL =
            try container.decodeIfPresent(
                String.self,
                forKey: .imageURL
            )

        // New multi-image field.
        // Existing posts without imageURLs get an empty array.
        self.imageURLs =
            try container.decodeIfPresent(
                [String].self,
                forKey: .imageURLs
            ) ?? []

        self.mediaType =
            try container.decodeIfPresent(
                String.self,
                forKey: .mediaType
            )

        self.ownerId =
            try container.decode(
                String.self,
                forKey: .ownerId
            )

        self.createdAt =
            try container.decodeIfPresent(
                Date.self,
                forKey: .createdAt
            )

        self.likes =
            try container.decodeIfPresent(
                Int.self,
                forKey: .likes
            ) ?? 0

        self.reposts =
            try container.decodeIfPresent(
                Int.self,
                forKey: .reposts
            ) ?? 0
        
        self.shares =
            try container.decodeIfPresent(
                Int.self,
                forKey: .shares
            ) ?? 0
            

        self.comments =
            try container.decodeIfPresent(
                Int.self,
                forKey: .comments
            ) ?? 0

        self.user = nil
    }
}
