//
//  GelbooruViewerApp.swift
//  GelbooruViewer
//
//  Created by Amrit Bhogal on 27/05/2024.
//

import SwiftUI
import SwiftData
import Foundation

//@Model
//class PostModel {
//    var post: Post
//    
//    init(post: Post) {
//        self.post = post
//    }
//}

struct MainView: View  {
    @Binding var apiKey: String?
    @Binding var userID: String?
    
    var body: some View {
        if let apiKey = apiKey, let userID = userID {
            ContentView(gelbooru: Gelbooru(apiKey: apiKey, userID: userID))
        } else {
            SetupView { apiKey, userID in
                try saveToKeychain(service: "Gelbooru", account: "apiKey", data: apiKey)
                try saveToKeychain(service: "Gelbooru", account: "userID", data: userID)
                self.apiKey = apiKey
                self.userID = userID
            }
        }
    }
}


@Model
class TagModel: ObservableObject {
    var tag: String
    var id: Int
    var count: Int
    
    init(tag: String, id: Int, count: Int) {
        self.tag = tag
        self.id = id
        self.count = count
    }
}


@main
struct GelbooruViewerApp: App {
    @State private var apiKey: String? = nil
    @State private var userID: String? = nil
    
    var body: some Scene {
        WindowGroup {
            MainView(apiKey: $apiKey, userID: $userID)
                .onAppear {
                    apiKey = readFromKeychain(service: "Gelbooru", account: "apiKey")
                    userID = readFromKeychain(service: "Gelbooru", account: "userID")
                }
        }
        .modelContainer(for: TagModel.self)
    }
}
