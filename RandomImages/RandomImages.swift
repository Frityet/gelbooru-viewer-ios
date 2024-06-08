//
//  RandomImages.swift
//  RandomImages
//
//  Created by Amrit Bhogal on 29/05/2024.
//

import WidgetKit
import Gelbooru
import SwiftUI

let PLACEHOLDER_URL = "https://gelbooru.com/layout/404.jpg"

extension Gelbooru {
    func randomPost(tags: Set<String>) async throws -> Post {
        var tags = tags
        tags.insert("sort:random")
        let posts = try await self.getPosts(tags: tags, limit: 1)
        return posts[0]
    }
}

struct RandomImageEntry: TimelineEntry {
    let post: Post
    let date: Date
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> RandomImageEntry {
        RandomImageEntry(post: Post(id: 0, tags: [], fileURL: PLACEHOLDER_URL, rating: .general), date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (RandomImageEntry) -> Void) {
        let entry = RandomImageEntry(post: Post(id: 0, tags: [], fileURL: PLACEHOLDER_URL, rating: .general), date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RandomImageEntry>) -> Void) {
        let gelbooru = Gelbooru(apiKey: "", userID: "")
        Task {
            let post = try! await gelbooru.randomPost(tags: ["kagamine_rin", "1girl", "-rating:explicit", "-rating:questionable"])
            let entry = RandomImageEntry(post: post, date: Date())
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct ImageView: View {
    let post: Post

    var body: some View {
        AsyncImage(url: URL(string: post.fileURL)) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure:
                Image(systemName: "exclamationmark.triangle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            @unknown default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(contentMode: .fit)
        .clipped()
    }
}

struct RandomImages: Widget {
    let kind: String = "RandomImages"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ImageView(post: entry.post)
                .containerBackground(for: .widget) {
                    Color(.systemBackground)
                }
        }
        .configurationDisplayName("Random Images")
        .description("Random images from Gelbooru")
    }
}
