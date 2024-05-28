//
//  ContentView.swift
//  GelbooruViewer
//
//  Created by Amrit Bhogal on 27/05/2024.
//

import SwiftUI
import SwiftData

struct FetchedPostsView: View {
    @Binding var fetchedPosts: [Post]
    var loadPosts: (_ reset: Bool) async -> Void
    @Binding var isLoading: Bool
    
    var namespace: Namespace.ID
    
    var body: some View {
        VStack {
            if fetchedPosts.isEmpty {
                Text("No posts fetched")
                    .padding()
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(fetchedPosts, id: \.id) { post in
                            PostView(post: post, namespace: namespace)
                                .onAppear {
                                    if post == fetchedPosts.last && !isLoading {
                                        Task {
                                            await loadPosts(false)
                                        }
                                    }
                                }
                        }
                        if isLoading {
                            ProgressView()
                                .padding()
                        }
                    }
                }
            }
        }
        .navigationTitle("Fetched Posts")
        .onAppear {
            Task {
                await loadPosts(false)
            }
        }
    }
}

struct ContentView: View {
    let gelbooru: Gelbooru
    @State var searchTags = Set([ "kagamine_rin", "1girl", "-rating:explicit", "-rating:questionable" ])
    @State var contentFilter: Set<Post.Rating> = [ .questionable, .explicit ]
    @State var fetchedPosts: [Post] = []
    @State private var currentPage = 0
    @State private var isLoading = false
    @State private var showFetchedPosts = false
    
    @Namespace private var animationNamespace
    
    @Query var cachedTags: [TagModel]
    @Environment(\.modelContext) var modelContext

    func fetchPosts(page: Int = 0, postLimit: Int = 10) async throws -> [Post] {
        return try await gelbooru.getPosts(tags: searchTags, limit: postLimit, page: page)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    NavigationLink("Select Tags", destination: TagSelectionView(gelbooru: gelbooru, selectedTags: $searchTags))
                    EditableTagsView(tags: $searchTags)
                    
                    VStack(alignment: .leading) {
                        Text("Content to hide")
                            .font(.title3)
                        
                        ForEach(Post.Rating.allCases, id: \.self) { rating in
                            HStack {
                                Text(rating.rawValue.capitalized)
                                Spacer()
                                
                                if contentFilter.contains(rating) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .onTapGesture {
                                            contentFilter.remove(rating)
                                            searchTags.remove("-rating:\(rating.rawValue)")
                                        }
                                } else {
                                    Image(systemName: "circle")
                                        .onTapGesture {
                                            contentFilter.insert(rating)
                                            searchTags.insert("-rating:\(rating.rawValue)")
                                        }
                                }
                            }
                            .contentShape(Rectangle()) // Make the entire row tappable
                        }
                    }
                    
                    Button("Reset tag cache") {
                        do {
                            try modelContext.delete(model: TagModel.self)
                        } catch {
                            print("Failed to delete tags: \(error)")
                        }
                    }
                    .foregroundColor(.red)
                    
                    Button("Fetch Posts") {
                        Task {
                            await loadPosts(reset: true)
                            showFetchedPosts = true
                        }
                    }
                }
                
                NavigationLink(value: showFetchedPosts, label: { EmptyView() })
                .navigationDestination(isPresented: $showFetchedPosts) {
                    FetchedPostsView(fetchedPosts: $fetchedPosts, loadPosts: loadPosts, isLoading: $isLoading, namespace: animationNamespace)
                }
            }
            .navigationTitle("Fetch Posts")
        }
    }
    
    private func loadPosts(reset: Bool = false) async {
        if isLoading { return }
        isLoading = true
        
        if reset {
            currentPage = 0
            fetchedPosts = []
        }
        
        do {
            let newPosts = try await fetchPosts(page: currentPage)
            
            fetchedPosts.append(contentsOf: newPosts)
            currentPage += 1
        } catch {
            print("Failed to fetch posts: \(error)")
        }
        
        isLoading = false
    }
}

#Preview {
    ContentView(gelbooru: Gelbooru(apiKey: "", userID: ""))
}
