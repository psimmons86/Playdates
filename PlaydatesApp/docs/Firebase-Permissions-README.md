# Firebase Permissions Guide

## Issue: "Missing or insufficient privileges" Error

If you're experiencing a "Missing or insufficient privileges" error when trying to access Firebase data (particularly when clicking on activities in the Explore view), this is likely due to restrictive security rules in your Firebase project.

## Solution

You need to update your Firebase security rules to allow read access to the `activities` collection. Here's how:

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. In the left sidebar, click on "Firestore Database"
4. Click on the "Rules" tab
5. Update your security rules to allow read access to the activities collection

### Updated Firebase Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Activities collection - allow public read access
    match /activities/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // User profiles with data validation
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create, update: if request.auth != null && 
                             request.auth.uid == userId &&
                             request.resource.data.name is string &&
                             request.resource.data.email is string;
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // Friendships
    match /friendships/{friendshipId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
                     (request.resource.data.userID == request.auth.uid || 
                      request.resource.data.friendID == request.auth.uid) &&
                     request.resource.data.userID is string &&
                     request.resource.data.friendID is string;
      allow update, delete: if request.auth != null && 
                             (resource.data.userID == request.auth.uid || 
                              resource.data.friendID == request.auth.uid);
    }
    
    // Friend requests
    match /friendRequests/{requestId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
                     request.resource.data.senderID == request.auth.uid &&
                     request.resource.data.senderID is string &&
                     request.resource.data.recipientID is string;
      allow update, delete: if request.auth != null && 
                             (resource.data.senderID == request.auth.uid || 
                              resource.data.recipientID == request.auth.uid);
    }
    
    // Playdates
    match /playdates/{playdateId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.creatorId == request.auth.uid;
      allow update, delete: if request.auth != null && resource.data.creatorId == request.auth.uid;
    }
  }
}
```

6. Click "Publish" to apply the new rules
7. Return to your app and try again - the error should be resolved

## Security Note

The rules above allow public read access to the activities collection, which is appropriate for a public directory of activities. All other collections require authentication and have appropriate validation rules.

## Helper Script

We've included a helper script that provides these instructions:

```bash
./PlaydatesApp/fix_firebase_permissions.sh
```

## Code Changes

We've also updated the `ActivityViewModel.swift` file to handle Firebase permission errors more gracefully. When a permission error occurs, the app will now:

1. Display a clear error message to the user
2. Log the error for debugging purposes
3. Clear the activities array to avoid showing stale data

## More Information

For more information on Firebase security rules, visit:
[Firebase Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
