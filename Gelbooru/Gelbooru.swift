//
//  Gelbooru.swift
//
//
//  Created by Amrit Bhogal on 27/05/2024.
//

import Foundation

public struct Post: Decodable, Equatable {
    public enum Rating: String, Decodable, CaseIterable {
//        case safe
        case general
        case sensitive
        case questionable
        case explicit
    }

    public let id: Int
    public let createdAt: String
    public let score: Int
    public let width: Int
    public let height: Int
    public let md5: String
    public let directory: String
    public let image: String
    public let rating: Rating
    public let source: String
    public let change: Int
    public let owner: String
    public let creatorID: Int
    public let parentID: Int
    public let sample: Int
    public let previewHeight: Int
    public let previewWidth: Int
    public let tags: Set<String>
    public let title: String?
    public let hasNotes: String?
    public let hasComments: String?
    public let fileURL: String
    public let previewURL: String
    public let sampleURL: String?
    public let sampleHeight: Int
    public let sampleWidth: Int
    public let status: String?
    public let postLocked: Int
    public let hasChildren: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case score
        case width
        case height
        case md5
        case directory
        case image
        case rating
        case source
        case change
        case owner
        case creatorID = "creator_id"
        case parentID = "parent_id"
        case sample
        case previewHeight = "preview_height"
        case previewWidth = "preview_width"
        case tags
        case title
        case hasNotes = "has_notes"
        case hasComments = "has_comments"
        case fileURL = "file_url"
        case previewURL = "preview_url"
        case sampleURL = "sample_url"
        case sampleHeight = "sample_height"
        case sampleWidth = "sample_width"
        case status
        case postLocked = "post_locked"
        case hasChildren = "has_children"
    }

    public var url: String {
        return "https://gelbooru.org/index.php?page=post&s=view&id=\(id)"
    }

    public var imageURL: String {
        return "https://img3.gelbooru.com/images/\(directory)/\(image)"
    }

    public var previewImageURL: String {
        return "https://img3.gelbooru.com/thumbnails/\(directory)/thumbnail_\(image)"
    }

    public init(from decoder: Decoder) throws
    {
        let container        = try decoder.container(keyedBy: CodingKeys.self)
        id                   = try container.decode(Int.self,   forKey: .id)
        createdAt            = try container.decode(String.self,forKey: .createdAt)
        score                = try container.decode(Int.self,   forKey: .score)
        width                = try container.decode(Int.self,   forKey: .width)
        height               = try container.decode(Int.self,   forKey: .height)
        md5                  = try container.decode(String.self,forKey: .md5)
        directory            = try container.decode(String.self,forKey: .directory)
        image                = try container.decode(String.self,forKey: .image)
        rating               = try container.decode(Rating.self,forKey: .rating)
        source               = try container.decode(String.self,forKey: .source)
        change               = try container.decode(Int.self,   forKey: .change)
        owner                = try container.decode(String.self,forKey: .owner)
        creatorID            = try container.decode(Int.self,   forKey: .creatorID)
        parentID             = try container.decode(Int.self,   forKey: .parentID)
        sample               = try container.decode(Int.self,   forKey: .sample)
        previewHeight        = try container.decode(Int.self,   forKey: .previewHeight)
        previewWidth         = try container.decode(Int.self,   forKey: .previewWidth)
        tags                 = Set<String>((try container.decode(String.self, forKey: .tags)).split(separator: " ").map { String($0) })
        title                = try container.decodeIfPresent(String.self, forKey: .title)

        let notes            = try container.decode(String.self,forKey: .hasNotes)
        let comments         = try container.decode(String.self,forKey: .hasComments)
        let children         = try container.decode(String.self,forKey: .hasChildren)
        hasChildren         = children == "false"   ? nil : children
        hasNotes            = notes == "false"      ? nil : notes
        hasComments         = comments == "false"   ? nil : comments

        fileURL              = try container.decode(String.self, forKey: .fileURL)
        previewURL           = try container.decode(String.self, forKey: .previewURL)
        let surl             = try container.decode(String.self, forKey: .sampleURL)
        sampleURL            = surl == "" ? nil : surl
        sampleHeight         = try container.decode(Int.self, forKey: .sampleHeight)
        sampleWidth          = try container.decode(Int.self, forKey: .sampleWidth)
        status               = try container.decode(String.self, forKey: .status)
        postLocked           = try container.decode(Int.self, forKey: .postLocked)
    }

    //just for previews
    public init(id: Int, tags: Set<String>, fileURL: String, rating: Rating)
    {
        self.id = id
        self.tags = tags
        self.fileURL = fileURL
        self.createdAt = ""
        self.score = 0
        self.width = 0
        self.height = 0
        self.md5 = ""
        self.directory = ""
        self.image = ""
        self.rating = rating
        self.source = ""
        self.change = 0
        self.owner = ""
        self.creatorID = 0
        self.parentID = 0
        self.sample = 0
        self.previewHeight = 0
        self.previewWidth = 0
        self.title = ""
        self.hasNotes = ""
        self.hasComments = ""
        self.previewURL = ""
        self.sampleURL = ""
        self.sampleHeight = 0
        self.sampleWidth = 0
        self.status = ""
        self.postLocked = 0
        self.hasChildren = ""
    }

    public static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct Tag: Decodable, Equatable, Hashable {
    public let id: Int
    public let name: String
    public let count: Int
    public let type: Int
    public let ambiguous: Int

    public var nameWithoutCategory: String {
        return name.replacingOccurrences(of: "_\\(.*\\)", with: "", options: .regularExpression)
    }

    public var category: String? {
        let regex = try! NSRegularExpression(pattern: "_\\(.*\\)", options: [])
        let range = NSRange(location: 0, length: name.utf16.count)
        let match = regex.firstMatch(in: name, options: [], range: range)
        if let match = match {
            return (name as NSString).substring(with: match.range)
        }
        return nil
    }

    public static func == (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension [Tag] {
    public func toStringSet() -> Set<String> {
        return Set(self.map { $0.name })
    }
}

private struct Attributes : Decodable {
    public let count: Int
    public let pid: Int?
    public let limit: Int
}

private struct PostListResponse : Decodable {
    public let attributes: Attributes
    let post: [Post]

    enum CodingKeys: String, CodingKey {
        case attributes = "@attributes"
        case post
    }
}

private struct TagListResponse : Decodable {
    public let attributes: Attributes
    let tag: [Tag]?

    enum CodingKeys: String, CodingKey {
        case attributes = "@attributes"
        case tag
    }
}

@available(macOS 12.0, *)
@available(iOS 15.0, *)
public struct Gelbooru {
    public enum Error : Swift.Error {
        case invalidLimit(limit: Int)
        case requestError(statusCode: Int)
    }

    public static let BASE_URL = "https://gelbooru.com/index.php?"

    public let apiKey: String
    public let userID: String

    public var postRequestURL: String {
        return "\(Gelbooru.BASE_URL)page=dapi&s=post&q=index&json=1&api_key=\(apiKey)&user_id=\(userID)"
    }

    public var tagRequestURL: String {
        return "\(Gelbooru.BASE_URL)page=dapi&s=tag&q=index&json=1&api_key=\(apiKey)&user_id=\(userID)"
    }

    public init(apiKey: String, userID: String)
    {
        self.apiKey = apiKey
        self.userID = userID
    }

    public func getPosts(tags: Set<String> = Set(), limit: Int = 100, page: Int = 0) async throws -> [Post]
    {
        if limit > 100 {
            throw Error.invalidLimit(limit: limit)
        }

        let url = "\(postRequestURL)&limit=\(limit)&pid=\(page)&tags=\(tags.joined(separator: "+"))"
        let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)

        return try JSONDecoder().decode(PostListResponse.self, from: data).post
    }

    public func getTags(limit: Int = 100, pageID: Int = 0) async throws -> [Tag]?
    {
        if limit > 100 {
            throw Error.invalidLimit(limit: limit)
        }

        let url = "\(tagRequestURL)&limit=\(limit)&pid=\(pageID)"
        let (data, resp) = try await URLSession.shared.data(from: URL(string: url)!)
        if let error = resp as? HTTPURLResponse, error.statusCode != 200 {
            throw Error.requestError(statusCode: error.statusCode)
        }

        return try JSONDecoder().decode(TagListResponse.self, from: data).tag
    }

}
