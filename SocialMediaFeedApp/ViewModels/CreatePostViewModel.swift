//
//  CreatePostViewModel.swift
//  SocialMediaFeedApp
//
//  Created by Prince Lunagariya on 21/04/26.
//

import SwiftUI
import CoreData
import Combine

final class CreatePostViewModel: ObservableObject {

    @Published var selectedImage: UIImage?
    @Published var descriptionText: String = ""
    @Published var locationText: String = ""
    @Published var isSaving: Bool = false
    @Published var showImagePicker: Bool = false
    @Published var errorMessage: String?
    @Published var didSave: Bool = false

    var canSave: Bool {
        let hasContent = selectedImage != nil || !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasLocation = !locationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasContent && hasLocation
    }

    func savePost(context: NSManagedObjectContext) {
        guard canSave else {
            errorMessage = "Please add a location and at least an image or description before posting."
            return
        }
        isSaving = true
        errorMessage = nil

        let post = Post(context: context)
        post.id = UUID()
        post.createdAt = Date()
        post.postDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        post.location = locationText.trimmingCharacters(in: .whitespacesAndNewlines)
        post.isLiked = false
        post.likeCount = 0

        if let image = selectedImage {
            post.imageData = image.jpegData(compressionQuality: 0.7)
        }

        do {
            try context.save()
            isSaving = false
            resetForm()
            didSave = true
        } catch {
            isSaving = false
            errorMessage = "Failed to save post. Please try again."
            print("CreatePostViewModel save error: \(error)")
        }
    }
    
    func resetForm() {
        selectedImage = nil
        descriptionText = ""
        locationText = ""
        errorMessage = nil
        showImagePicker = false
        didSave = false
    }
}
