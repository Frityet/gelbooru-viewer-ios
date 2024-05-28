//
//  PostView.swift
//  GelbooruViewer
//
//  Created by Amrit Bhogal on 27/05/2024.
//

import SwiftUI

struct FullImageView: View {
    @Environment(\.presentationMode) var presentationMode
    var imageURL: String
    var animationNamespace: Namespace.ID

    var body: some View {
        VStack {
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .matchedGeometryEffect(id: imageURL, in: animationNamespace)
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(.gray)
                        .matchedGeometryEffect(id: imageURL, in: animationNamespace)
                @unknown default:
                    EmptyView()
                }
            }
            .navigationTitle("Full Image")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                // Dismiss the full screen view
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}


struct ThumbnailImageView: View {
    var imageURL: String
    @Namespace var animationNamespace: Namespace.ID
    @State private var showFullImage = false

    var body: some View {
        VStack {
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 100, height: 100)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipped()
                        .matchedGeometryEffect(id: imageURL, in: animationNamespace)
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipped()
                        .foregroundColor(.gray)
                        .matchedGeometryEffect(id: imageURL, in: animationNamespace)
                @unknown default:
                    EmptyView()
                }
            }
            .onTapGesture {
                showFullImage.toggle()
            }
            .fullScreenCover(isPresented: $showFullImage) {
                FullImageView(imageURL: imageURL, animationNamespace: animationNamespace)
            }
        }
    }
}

struct RatingView : View {
    var rating: Post.Rating
    
    var body: some View {
        switch rating {
        case .general:
            return Text("General")
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(5)
        case .safe:
            return Text("Safe")
                .background(.green)
                .foregroundColor(.white)
                .cornerRadius(5)
        case .questionable:
            return Text("Questionable")
                .background(.orange)
                .foregroundColor(.white)
                .cornerRadius(5)
        case .explicit:
            return Text("Explicit")
                .background(.red)
                .foregroundColor(.white)
                .cornerRadius(5)
        case .sensitive:
            return Text("Sensitive")
                .background(.purple)
                .foregroundColor(.white)
                .cornerRadius(5)
        }
    }
}


struct PostView : View {
    @State private var showFullImage = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String? = nil
    var post: Post
    @Namespace private var animationNamespace

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Post ID: \(post.id)")
                .font(.headline)
                .padding(.bottom, 5)

            RatingView(rating: post.rating)

            TagsView(tags: post.tags)
                .padding(.vertical, 5)

            AsyncImage(url: URL(string: post.sampleURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: 200)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .cornerRadius(10)
                        .matchedGeometryEffect(id: post.id, in: animationNamespace)
                        .onTapGesture {
                            showFullImage.toggle()
                        }
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .foregroundColor(.gray)
                        .matchedGeometryEffect(id: post.id, in: animationNamespace)
                        .onTapGesture {
                            showFullImage.toggle()
                        }
                @unknown default:
                    EmptyView()
                }
            }

            Button("Save") {
                Task {
                    guard let url = URL(string: post.fileURL) else {
                        errorMessage = "Invalid URL \(post.fileURL)"
                        showErrorAlert = true
                        return
                    }

                    let data: Data
                    do {
                        data = try Data(contentsOf: url)
                    } catch {
                        errorMessage = "Failed to download image: \(error.localizedDescription)"
                        showErrorAlert = true
                        return
                    }

                    guard let image = UIImage(data: data) else {
                        errorMessage = "Failed to create image from data"
                        showErrorAlert = true
                        return
                    }

                    showErrorAlert = false
                    errorMessage = nil
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "An unknown error occurred"), dismissButton: .default(Text("OK")))
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(color: Color(.black).opacity(0.1), radius: 5, x: 0, y: 5)
        .padding([.horizontal, .top])
        .fullScreenCover(isPresented: $showFullImage) {
            FullImageView(imageURL: post.fileURL, animationNamespace: animationNamespace)
        }
    }
}


#Preview {
    PostView(post: Post(id: 100, tags: ["tag1", "tag2"], fileURL: "https://img3.gelbooru.com//images/4a/81/4a8120e516f2440fb0484b3b18d09fa5.png", rating: .safe))
        .previewLayout(.sizeThatFits)
        .padding(10)
}
