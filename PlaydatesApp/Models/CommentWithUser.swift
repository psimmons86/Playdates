import Foundation

public struct CommentWithUser: Identifiable {
    public let comment: Comment
    public let user: User
    
    public var id: String {
        return comment.id
    }
    
    public init(comment: Comment, user: User) {
        self.comment = comment
        self.user = user
    }
}
