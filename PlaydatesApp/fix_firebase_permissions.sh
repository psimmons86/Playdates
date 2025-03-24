#!/bin/bash

# This script helps fix Firebase permission issues by providing instructions
# on how to update Firebase security rules

echo "Firebase Permission Fix Helper"
echo "============================="
echo ""
echo "You're experiencing 'Missing or insufficient privileges' errors when trying to access"
echo "Firebase data. This is likely due to restrictive security rules in your Firebase project."
echo ""
echo "To fix this issue, follow these steps:"
echo ""
echo "1. Go to the Firebase Console: https://console.firebase.google.com/"
echo ""
echo "2. Select your project"
echo ""
echo "3. In the left sidebar, click on 'Firestore Database'"
echo ""
echo "4. Click on the 'Rules' tab"
echo ""
echo "5. Update your security rules to allow read access to the 'activities' collection."
echo "   Here are the updated rules that incorporate your existing rules:"
echo ""
echo "   rules_version = '2';"
echo "   service cloud.firestore {"
echo "     match /databases/{database}/documents {"
echo "       // Activities collection - allow public read access"
echo "       match /activities/{document=**} {"
echo "         allow read: if true;"
echo "         allow write: if request.auth != null;"
echo "       }"
echo "       "
echo "       // User profiles with data validation"
echo "       match /users/{userId} {"
echo "         allow read: if request.auth != null;"
echo "         allow create, update: if request.auth != null && "
echo "                                request.auth.uid == userId &&"
echo "                                request.resource.data.name is string &&"
echo "                                request.resource.data.email is string;"
echo "         allow delete: if request.auth != null && request.auth.uid == userId;"
echo "       }"
echo "       "
echo "       // Friendships"
echo "       match /friendships/{friendshipId} {"
echo "         allow read: if request.auth != null;"
echo "         allow create: if request.auth != null && "
echo "                        (request.resource.data.userID == request.auth.uid || "
echo "                         request.resource.data.friendID == request.auth.uid) &&"
echo "                        request.resource.data.userID is string &&"
echo "                        request.resource.data.friendID is string;"
echo "         allow update, delete: if request.auth != null && "
echo "                                (resource.data.userID == request.auth.uid || "
echo "                                 resource.data.friendID == request.auth.uid);"
echo "       }"
echo "       "
echo "       // Friend requests"
echo "       match /friendRequests/{requestId} {"
echo "         allow read: if request.auth != null;"
echo "         allow create: if request.auth != null && "
echo "                        request.resource.data.senderID == request.auth.uid &&"
echo "                        request.resource.data.senderID is string &&"
echo "                        request.resource.data.recipientID is string;"
echo "         allow update, delete: if request.auth != null && "
echo "                                (resource.data.senderID == request.auth.uid || "
echo "                                 resource.data.recipientID == request.auth.uid);"
echo "       }"
echo "       "
echo "       // Playdates"
echo "       match /playdates/{playdateId} {"
echo "         allow read: if request.auth != null;"
echo "         allow create: if request.auth != null && request.resource.data.creatorId == request.auth.uid;"
echo "         allow update, delete: if request.auth != null && resource.data.creatorId == request.auth.uid;"
echo "       }"
echo "     }"
echo "   }"
echo ""
echo "6. Click 'Publish' to apply the new rules"
echo ""
echo "7. Return to your app and try again - the error should be resolved"
echo ""
echo "IMPORTANT SECURITY NOTE:"
echo "The rules above allow public read access to the activities collection, which is"
echo "appropriate for a public directory of activities. All other collections require"
echo "authentication and have appropriate validation rules."
echo ""
echo "For more information on Firebase security rules, visit:"
echo "https://firebase.google.com/docs/firestore/security/get-started"
echo ""
