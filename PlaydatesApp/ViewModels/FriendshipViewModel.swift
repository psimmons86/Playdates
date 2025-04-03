import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Combine
import SwiftUI

// Original FriendshipViewModel content has been refactored into:
// - FriendManagementViewModel (for friends, requests, user search)
// - ChatViewModel (for chat messages between friends)
// - PlaydateInvitationViewModel (for playdate invitations)

// This file can likely be removed if no longer referenced,
// or repurposed if there's a need for a coordinating ViewModel.
// For now, leaving a placeholder class definition.

class FriendshipViewModel_Deprecated: ObservableObject {
    // This class is deprecated. Please use:
    // - FriendManagementViewModel
    // - ChatViewModel
    // - PlaydateInvitationViewModel
    
    // You might need to update views that previously used FriendshipViewModel
    // to inject and use the appropriate new ViewModel(s).
    
    init() {
        print("⚠️ FriendshipViewModel_Deprecated initialized. This class should be replaced.")
    }
}

// TODO: Search the project for usages of 'FriendshipViewModel' and update them
//       to use 'FriendManagementViewModel', 'ChatViewModel', or 'PlaydateInvitationViewModel'
//       as appropriate. Once all usages are updated, this file can be safely deleted.
