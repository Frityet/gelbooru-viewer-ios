//
//  TagViews.swift
//  GelbooruViewer
//
//  Created by Amrit Bhogal on 27/05/2024.
//

import SwiftUI
import SwiftData

struct TagsView: View {
    var tags: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags, id: \.self) { tag in
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

struct TagSelectionView : View {
    @Query var cachedTags: [TagModel]
    @Environment(\.modelContext) var modelContext
    let gelbooru: Gelbooru
    @Binding var selectedTags: Set<String>
    
    @State private var isLoading: Bool = false
    @State private var searchText: String = ""
    
    @State private var showErrorAlert: Bool = false
    @State private var errorText: String = ""
    
    private var filteredTags: [TagModel] {
        if searchText.isEmpty {
            return cachedTags
        } else {
            return cachedTags.filter { $0.tag.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // Large searchable list where you can select tags
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
                                    if tagModel == cachedTags.last && !isLoading {
                                        Task {
                                            await populateTags()
                                        }
                                    }
                                }
                            Spacer()
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
            .searchable(text: $searchText)
            .navigationTitle("Select Tags")
            .onAppear {
                Task {
                    if cachedTags.isEmpty {
                        await populateTags()
                    }
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
    
    private func populateTags() async {
        if isLoading { return }
        isLoading = true
        
        //There are ~10098 pages. No that is not a typo. Ten thousand ninety eight pages.
        //That means we are doing 10098 GET requests.
        //Theres no way apple will approve this
        do {
            //start at the latest page that was cached
            var page = cachedTags.count
            while true {
                let newTags = try await gelbooru.getTags(pageID: page)
                if newTags == nil || newTags!.isEmpty {
                    break
                }
                
                for tag in newTags! {
                    let newTagModel = TagModel(tag: tag.name, id: tag.id, count: tag.count)
                    modelContext.insert(newTagModel)
                }
                
                page += 1
                try modelContext.save()
            }
        } catch {
            errorText = error.localizedDescription
            showErrorAlert = true
        }
        
        isLoading = false
    }
}
