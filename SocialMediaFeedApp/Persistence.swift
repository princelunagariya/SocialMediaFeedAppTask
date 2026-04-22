//
//  Persistence.swift
//  SocialMediaFeedApp
//
//  Created by Prince Lunagariya on 21/04/26.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        for i in 0..<3 {
            let post = Post(context: viewContext)
            post.id = UUID()
            post.postDescription = "Sample post #\(i + 1) — SwiftUI is amazing! 🚀"
            post.location = "San Francisco, CA"
            post.createdAt = Date().addingTimeInterval(Double(-i) * 3600)
            post.isLiked = i == 0
            post.likeCount = Int32(i * 3)

            let comment = Comment(context: viewContext)
            comment.id = UUID()
            comment.text = "Great post!"
            comment.createdAt = Date()
            comment.post = post
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SocialMediaFeedApp")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("CoreData save error: \(nsError), \(nsError.userInfo)")
        }
    }
}
