//
//  FeedViewModel.swift
//  SocialMediaFeedApp
//
//  Created by Prince Lunagariya on 21/04/26.
//

import SwiftUI
import CoreData
import Combine

final class FeedViewModel: ObservableObject {

    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    func toggleLike(post: Post) {
        post.isLiked.toggle()
        post.likeCount = post.isLiked ? post.likeCount + 1 : max(0, post.likeCount - 1)
        save()
    }

    func addComment(to post: Post, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let comment = Comment(context: viewContext)
        comment.id = UUID()
        comment.text = trimmed
        comment.createdAt = Date()
        comment.post = post
        save()
    }

    func deletePost(_ post: Post) {
        viewContext.delete(post)
        save()
    }

    func sharePost(_ post: Post) {
        var activityItems: [Any] = []

        if let description = post.postDescription, !description.isEmpty {
            activityItems.append(description)
        }
        if let imgData = post.imageData, let image = UIImage(data: imgData) {
            activityItems.append(image)
        }
        if activityItems.isEmpty {
            activityItems.append("Check out this post!")
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        if let popover = vc.popoverPresentationController {
            popover.sourceView = rootVC.view
            let bounds = rootVC.view.bounds
            popover.sourceRect = CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        rootVC.present(vc, animated: true)
    }
    func sortedComments(for post: Post) -> [Comment] {
        let set = post.comments as? Set<Comment> ?? []
        return set.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
    }

    private func save() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            print("FeedViewModel save error: \(error)")
        }
    }
}
