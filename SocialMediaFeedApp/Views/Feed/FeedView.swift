//
//  FeedView.swift
//  SocialMediaFeedApp
//

import SwiftUI
import CoreData

struct FeedView: View {

    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Post.createdAt, ascending: false)],
        animation: .none
    )
    private var posts: FetchedResults<Post>

    @State private var expandedPostID: UUID? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                if posts.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(posts) { post in
                            PostCardView(post: post, expandedPostID: $expandedPostID)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Feed")
                        .font(.system(size: 18, weight: .bold))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !posts.isEmpty {
                        Text("\(posts.count) post\(posts.count == 1 ? "" : "s")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                    }
                }
            }
            .onAppear { configureNavBar() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(colors: [.accentColor, .purple],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            VStack(spacing: 8) {
                Text("No Posts Yet")
                    .font(.system(size: 22, weight: .bold))
                Text("Create your first post using the + tab below.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .padding()
    }

    private func configureNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = UIColor.separator
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance    = appearance
    }
}

#Preview {
    FeedView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
