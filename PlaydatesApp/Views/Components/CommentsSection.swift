import SwiftUI

/// Comments section with generic row type
@available(iOS 17.0, *)
public struct CommentsSection<RowType: View>: View {
    private let comments: [CommentWithUser]
    @Binding private var commentText: String
    private let isLoadingComments: Bool
    private let onSubmitComment: () -> Void
    private let rowBuilder: (CommentWithUser) -> RowType
    
    public init(
        comments: [CommentWithUser], 
        commentText: Binding<String>, 
        isLoadingComments: Bool,
        onSubmitComment: @escaping () -> Void,
        @ViewBuilder rowBuilder: @escaping (CommentWithUser) -> RowType
    ) {
        self.comments = comments
        self._commentText = commentText
        self.isLoadingComments = isLoadingComments
        self.onSubmitComment = onSubmitComment
        self.rowBuilder = rowBuilder
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments")
                .font(.headline)
                .foregroundColor(ColorTheme.darkPurple)
            
            if isLoadingComments {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 12)
            } else if comments.isEmpty {
                Text("No comments yet")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
                    .padding(.vertical, 8)
            } else {
                // Comments list
                VStack(spacing: 16) {
                    ForEach(comments) { commentWithUser in
                        rowBuilder(commentWithUser)
                    }
                }
            }
            
            // Comment input
            HStack(spacing: 12) {
                TextField("Add a comment...", text: $commentText)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                
                Button(action: onSubmitComment) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(commentText.isEmpty ? ColorTheme.lightText : ColorTheme.primary)
                }
                .disabled(commentText.isEmpty)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

/// Default comment row implementation
@available(iOS 17.0, *)
public struct DefaultCommentRow: View {
    private let commentWithUser: CommentWithUser
    
    public init(commentWithUser: CommentWithUser) {
        self.commentWithUser = commentWithUser
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // User avatar
            if commentWithUser.comment.isSystem ?? false {
                Image(systemName: "bell.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(ColorTheme.lightText)
                    .clipShape(Circle())
            } else {
                ProfileImageView(imageURL: commentWithUser.user.profileImageURL, size: 36)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // User name and time
                HStack {
                    Text(commentWithUser.user.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ColorTheme.darkPurple)
                    
                    Spacer()
                    
                    Text(timeAgo(date: commentWithUser.comment.createdAt))
                        .font(.caption)
                        .foregroundColor(ColorTheme.lightText)
                }
                
                // Comment text
                Text(commentWithUser.comment.text)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private func timeAgo(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
