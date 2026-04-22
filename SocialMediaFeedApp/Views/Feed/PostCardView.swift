//
//  PostCardView.swift
//  SocialMediaFeedApp
//

import SwiftUI
import CoreData

struct PostCardView: View {


    @ObservedObject var post: Post
    @Environment(\.managedObjectContext) private var viewContext

    @Binding var expandedPostID: UUID?
    @State private var commentText = ""
    @State private var showDeleteAlert = false

    init(post: Post, expandedPostID: Binding<UUID?>) {
        self.post = post
        _expandedPostID = expandedPostID
    }

    private var showComments: Bool {
        expandedPostID == post.id
    }

    private var postComments: [Comment] {
        let set = post.comments as? Set<Comment> ?? []
        return set.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            postImageView
            cardContent
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .alert("Delete Post?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deletePost() }
        } message: {
            Text("Are you sure you want to permanently delete this post?")
        }
    }

    @ViewBuilder
    private var postImageView: some View {
        if let data = post.imageData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .clipped()
                .contentShape(Rectangle())
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemGray5), Color(.systemGray4)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(Color(.systemGray2))
                    Text("No Image").font(.caption).foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 160)
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                if let loc = post.location, !loc.isEmpty {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.accentColor)
                    Text(loc)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if let date = post.createdAt {
                    Text(date, style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(Color(.systemGray2))
                }

                Menu {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Post", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(.systemGray2))
                        .padding(.leading, 8)
                        .contentShape(Rectangle())
                }
            }

            if let desc = post.postDescription, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            actionRow

            if showComments {
                commentSection.transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            likeChip
                .contentShape(Rectangle())
                .onTapGesture { toggleLike() }

            commentChip
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if expandedPostID == post.id {
                            expandedPostID = nil
                        } else {
                            expandedPostID = post.id
                        }
                    }
                }

            shareChip
                .contentShape(Rectangle())
                .onTapGesture { sharePost() }
        }
    }

    private var likeChip: some View {
        HStack(spacing: 6) {
            Image(systemName: post.isLiked ? "heart.fill" : "heart")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(post.isLiked ? .red : Color(.systemGray))
                .scaleEffect(post.isLiked ? 1.15 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: post.isLiked)
            Text("\(post.likeCount)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(post.isLiked ? .red : Color(.systemGray))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(post.isLiked ? Color.red.opacity(0.1) : Color(.systemGray6))
        )
    }

    private var commentChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "bubble.right")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(showComments ? .accentColor : Color(.systemGray))
            Text("\(postComments.count)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(showComments ? .accentColor : Color(.systemGray))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(showComments ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
        )
    }

    private var shareChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 20, weight: .medium))
            Text("Share")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(Color(.systemGray))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }

    @ViewBuilder
    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            if postComments.isEmpty {
                Text("No comments yet. Be the first!")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(postComments, id: \.id) { c in
                        CommentBubbleView(comment: c)
                    }
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(.systemGray3))

                HStack(spacing: 6) {
                    TextField("Add a comment…", text: $commentText, axis: .vertical)
                        .font(.system(size: 14))
                        .lineLimit(1...4)
                        .submitLabel(.send)
                        .onSubmit { submitComment() }

                    if !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.accentColor)
                            .contentShape(Rectangle())
                            .onTapGesture { submitComment() }
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private func toggleLike() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            post.isLiked.toggle()
            post.likeCount = post.isLiked ? post.likeCount + 1 : max(0, post.likeCount - 1)
        }
        save()
    }

    private func submitComment() {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let c = Comment(context: viewContext)
        c.id = UUID(); c.text = text; c.createdAt = Date(); c.post = post
        save()
        withAnimation { commentText = "" }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func sharePost() {
        var items: [Any] = []
        if let d = post.postDescription, !d.isEmpty { items.append(d) }
        if let data = post.imageData, let img = UIImage(data: data) { items.append(img) }
        if items.isEmpty { items.append("Check out this post!") }

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root  = scene.windows.first?.rootViewController else { return }
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let pop = vc.popoverPresentationController {
            pop.sourceView = root.view
            pop.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY,
                                    width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        root.present(vc, animated: true)
    }

    private func save() {
        guard viewContext.hasChanges else { return }
        try? viewContext.save()
    }

    private func deletePost() {
        withAnimation {
            viewContext.delete(post)
            save()
        }
    }
}

struct CommentBubbleView: View {
    @ObservedObject var comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 26))
                .foregroundColor(Color(.systemGray3))

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("User").font(.system(size: 13, weight: .semibold))
                    Spacer()
                    if let d = comment.createdAt {
                        Text(d, style: .relative)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                Text(comment.text ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
