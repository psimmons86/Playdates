# Playdates App

A social platform for parents to organize and discover playdates for their children.

## Key Features

- Discover kid-friendly activities in your area
- Organize playdates with friends
- Connect with other parents
- Keep track of your child's interests and activities

## Technical Overview

### Architecture

The app uses a SwiftUI-based architecture with:

- **Firebase Firestore** for data storage
- **MVVM pattern** for view-model separation
- **Combine** for reactive updates

### App Structure

The app has been streamlined into two main tabs:

1. **Dashboard Tab** - Consolidates all content features:
   - Your upcoming playdates
   - Nearby and popular activities 
   - Activity categories and discovery

2. **Social Tab** - Consolidates all social features:
   - Friends list and friend management
   - Friend requests (incoming/outgoing)
   - User profile and children profiles

### Firebase Safety System

The app includes a comprehensive type safety system to prevent NSNumber/String conversion crashes:

- **Centralized Type Handling** in `ModelImports.swift`
- **Immediate Data Sanitization** at retrieval point
- **Safe Type Conversion** with specific accessor methods
- **Defensive Coding Patterns** using Firebase best practices

## Developer Guide

### Setup

1. Clone the repository
2. Run `pod install` to install dependencies
3. Open `Playdates.xcworkspace`
4. Create a Firebase project and add the GoogleService-Info.plist file

### Key Files

- **PlaydatesApp/Utils/ModelImports.swift**: Central type handling and Firebase utilities
- **PlaydatesApp/Views/MainTabView.swift**: Main UI with Dashboard and Social tabs
- **PlaydatesApp/ViewModels/...**: View models for business logic
- **PlaydatesApp/Models/...**: Data models for app entities

### Best Practices

When working with Firebase data:

1. **Always sanitize data immediately**:
   ```swift
   let data = FirebaseSafetyKit.sanitizeData(document.data()) ?? [:]
   ```

2. **Use safe accessors for all field extractions**:
   ```swift
   let name = FirebaseSafetyKit.getString(from: data, forKey: "name") ?? "Default"
   ```

3. **Try Firebase's built-in Codable support first**:
   ```swift
   do {
       // Try built-in decoding first
       return try document.data(as: ModelType.self)
   } catch {
       // Fall back to manual parsing with safety methods
       // ...
   }
   ```

## Build and Run

To build and run the app:

1. Select a simulator or device in Xcode
2. Press ⌘+R to build and run

## UI Testing

The app includes SwiftUI previews for most components. Access them by:

1. Opening any View file
2. Showing the Canvas (Editor > Canvas)
3. Using the "Resume" button to see the preview
