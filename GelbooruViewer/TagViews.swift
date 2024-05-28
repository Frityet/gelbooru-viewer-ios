//
//  TagViews.swift
//  GelbooruViewer
//
//  Created by Amrit Bhogal on 27/05/2024.
//

import SwiftUI
import SwiftData
import Combine

struct TagsView: View {
    var tags: Set<String>
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Array(tags), id: \.self) { tag in
                    Text(tag)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .cornerRadius(5)
                        .foregroundColor(.white)
                        .font(.footnote)
                }
            }
        }
    }
}

struct EditableTagsView: View {
    @Binding var tags: Set<String>
    @State private var tagText: String = ""
    
    var body: some View {
        VStack {
            //We cant use TagsView because we also want to be able to remove tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Array(tags), id: \.self) { tag in
                        Text(tag)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background({() -> Color in
                                if tag.starts(with: "-") {
                                    return Color.red
                                } else if tag.starts(with: "rating:") {
                                    return Color.gray
                                } else {
                                    return Color.blue
                                }
                            }())
                            .cornerRadius(5)
                            .foregroundColor(.white)
                            .font(.footnote)
                            .onTapGesture {
                                if !tag.starts(with: "rating:") && !tag.starts(with: "-rating:") {
                                    tags.remove(tag)
                                }
                            }
                    }
                }
            }
            
            HStack {
                TextField("Add tag", text: $tagText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    if !tagText.isEmpty {
                        tags.insert(tagText)
                        tagText = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                }
            }
        }
    }
}

struct TagSelectionView: View {
    @Query var cachedTags: [TagModel]
    @Environment(\.modelContext) var modelContext
    let gelbooru: Gelbooru
    @Binding var selectedTags: Set<String>
    
    @State private var isLoading: Bool = false
    @State private var searchText: String = ""
    
    @State private var showErrorAlert: Bool = false
    @State private var errorText: String = ""
    @State private var currentPage: Int = 0
    @State private var allTagsLoaded: Bool = false
    
    private var filteredTags: [TagModel] {
        if searchText.isEmpty {
            return cachedTags
        } else {
            return cachedTags.filter { $0.tag.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredTags, id: \.tag) { tagModel in
                    Button(action: {
                        if selectedTags.contains(tagModel.tag) {
                            selectedTags.remove(tagModel.tag)
                        } else {
                            selectedTags.insert(tagModel.tag)
                        }
                    }) {
                        HStack {
                            Text(tagModel.tag)
                                .onAppear {
                                    if tagModel == filteredTags.last && !isLoading && searchText.isEmpty && !allTagsLoaded {
                                        loadMoreTags()
                                    }
                                }
                            Spacer()
                            
                            Text("\(tagModel.count)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            
                            if selectedTags.contains(tagModel.tag) {
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())
                    }
                }
                
                if isLoading {
                    ProgressView()
                        .padding()
                }
            }
            .searchable(text: $searchText, prompt: "Search Tags")
            .onChange(of: searchText) { newValue in
                if newValue.isEmpty && !allTagsLoaded {
                    loadMoreTags()
                }
            }
            .navigationTitle("Select Tags, \(cachedTags.count) found")
            .onAppear {
                if cachedTags.isEmpty {
                    loadMoreTags()
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorText),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func loadMoreTags() {
        guard !isLoading else { return }
        isLoading = true

        Task {
            do {
                let newTags = try await gelbooru.getTags(pageID: currentPage)
                if let newTags = newTags, !newTags.isEmpty {
                    for tag in newTags {
                        if !cachedTags.contains(where: { $0.id == tag.id }) {
                            let newTagModel = TagModel(tag: tag.name, id: tag.id, count: tag.count)
                            modelContext.insert(newTagModel)
                        } else {
                            print("Tag \(tag.name) already exists")
                        }
                    }
                    currentPage += 1
                    try modelContext.save()
                } else {
                    allTagsLoaded = true
                }
            } catch {
                errorText = error.localizedDescription
                showErrorAlert = true
            }
            isLoading = false
        }
    }
}

#Preview {
    TagSelectionView(gelbooru: Gelbooru(apiKey: "", userID: ""), selectedTags: .constant([ "kagamine_rin", "1girl" ]))
}
