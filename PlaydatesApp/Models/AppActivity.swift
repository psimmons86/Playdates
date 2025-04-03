import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

public enum AppActivityType: String, Codable {
    case newPlaydate = "newPlaydate"
    case playdateUpdate = "playdateUpdate"
    case newFriend = "newFriend"
    case newComment = "newComment"
    case newGroupPost = "newGroupPost"
    case newCommunityEvent = "newCommunityEvent"
    case newSharedResource = "newSharedResource"
    case userJoined = "userJoined"
    case childAdded = "childAdded"
}

public struct AppActivity: Identifiable, Codable {
    @DocumentID public var id: String?
    public var type: AppActivityType
    public var title: String
    public var description: String
    public var timestamp: Date
    public var userID: String
    public var userName: String
    public var userProfileImageURL: String?
    public var contentImageURL: String? // Added for image content in the feed item
    public var likeCount: Int = 0       // Added for like count
    public var commentCount: Int = 0    // Added for comment count
    public var isLiked: Bool = false    // Added to track if current user liked this item (client-side state)

    // Optional related content IDs
    public var playdateID: String?
    public var commentID: String?
    public var groupID: String?
    public var postID: String?
    public var eventID: String?
    public var resourceID: String?
    public var childID: String?
    
    public init(id: String? = nil, 
                type: AppActivityType, 
                title: String, 
                description: String, 
                timestamp: Date = Date(), 
                userID: String, 
                userName: String, 
                userProfileImageURL: String? = nil,
                playdateID: String? = nil,
                commentID: String? = nil,
                groupID: String? = nil,
                postID: String? = nil,
                eventID: String? = nil,
                resourceID: String? = nil,
                childID: String? = nil,
                contentImageURL: String? = nil, // Added initializer parameter
                likeCount: Int = 0,             // Added initializer parameter
                commentCount: Int = 0,          // Added initializer parameter
                isLiked: Bool = false) {        // Added initializer parameter (usually set later based on user data)
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.timestamp = timestamp
        self.userID = userID
        self.userName = userName
        self.userProfileImageURL = userProfileImageURL
        self.contentImageURL = contentImageURL // Assign new property
        self.likeCount = likeCount             // Assign new property
        self.commentCount = commentCount       // Assign new property
        self.isLiked = isLiked                 // Assign new property
        self.playdateID = playdateID
        self.commentID = commentID
        self.groupID = groupID
        self.postID = postID
        self.eventID = eventID
        self.resourceID = resourceID
        self.childID = childID
    }
    
    // Helper method to create a formatted time string
    public var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    // Helper method to get the appropriate system icon for the activity type
    public var systemIcon: String {
        switch type {
        case .newPlaydate:
            return "calendar.badge.plus"
        case .playdateUpdate:
            return "calendar.badge.exclamationmark"
        case .newFriend:
            return "person.2.fill"
        case .newComment:
            return "bubble.left.fill"
        case .newGroupPost:
            return "text.bubble.fill"
        case .newCommunityEvent:
            return "calendar.badge.clock"
        case .newSharedResource:
            return "folder.fill.badge.person.crop"
        case .userJoined:
            return "person.fill.badge.plus"
        case .childAdded:
            return "figure.child"
        }
    }
    
    // Helper method to get the appropriate color for the activity type
    public var iconColor: String {
        switch type {
        case .newPlaydate, .playdateUpdate:
            return "primary"
        case .newFriend, .userJoined:
            return "blue"
        case .newComment, .newGroupPost:
            return "green"
        case .newCommunityEvent:
            return "purple"
        case .newSharedResource:
            return "orange"
        case .childAdded:
            return "pink"
        }
    }
}
