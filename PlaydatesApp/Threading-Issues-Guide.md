# Threading Issues Guide

This guide addresses the threading issues in the Playdates app, particularly focusing on UI updates happening off the main thread, which can cause crashes and visual glitches.

## The Problem

The app was experiencing threading issues where UI updates were happening off the main thread, causing errors like:

```
CopyUnsupported layout off the main thread for <SwiftUIActivityIndicatorView: 0x101e77480>
Modifying properties of a view's layer off the main thread is not allowed
```

These issues are common when working with Firebase Firestore, as it often delivers updates on background threads.

## The Solution

The solution is to ensure all UI updates happen on the main thread by wrapping them in `DispatchQueue.main.async` blocks. This has been implemented in the following files:

1. `ActivityViewModel.swift` - All methods that update `@Published` properties now dispatch these updates to the main thread
2. `ActivitySearchViewModel.swift` - Added debug logging and ensured UI updates happen on the main thread
3. `ActivitySearchView.swift` - Added location services debugging in the `onAppear` method

## Key Changes Made

### 1. Wrapping UI Updates in DispatchQueue.main.async

Before:
```swift
self.isLoading = false
self.activities = parsedActivities
```

After:
```swift
DispatchQueue.main.async {
    self.isLoading = false
    self.activities = parsedActivities
}
```

### 2. Adding Debug Logging

Added debug logging to help diagnose issues:

```swift
print("Debug: Location is nil when searching")
print("Debug: Searching for '\(searchQuery)' at location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
print("Debug: Received \(activities.count) activities from API")
```

### 3. Location Services Debugging

Added location services debugging in the `onAppear` method of `ActivitySearchView.swift`:

```swift
.onAppear {
    // Debug location services
    let locationManager = LocationManager.shared
    print("Debug: LocationManager authorization status: \(locationManager.authorizationStatus.rawValue)")
    print("Debug: Current location available: \(locationManager.location != nil)")
    if let location = locationManager.location {
        print("Debug: Current location coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
}
```

## Guidelines for Future Development

When working with asynchronous operations in SwiftUI, always follow these guidelines:

1. **Always update UI on the main thread**: Any property marked with `@Published` should only be updated on the main thread.

2. **Wrap Firebase callbacks in DispatchQueue.main.async**: Firebase callbacks run on background threads, so always wrap any UI updates in these callbacks with `DispatchQueue.main.async`.

3. **Be careful with completion handlers**: When using completion handlers that might be called from a background thread, ensure any UI updates inside them are dispatched to the main thread.

4. **Check for memory leaks**: Always use `[weak self]` in closures to prevent memory leaks, and check that `self` still exists before using it.

5. **Add debug logging for async operations**: Add debug logging to help diagnose issues with asynchronous operations, especially for network requests and location services.

## Example Pattern

Here's the pattern to follow for all asynchronous operations:

```swift
// Start an asynchronous operation
someAsyncOperation { [weak self] result in
    guard let self = self else { return }
    
    // IMPORTANT: Dispatch UI updates to the main thread
    DispatchQueue.main.async {
        // Update UI properties here
        self.isLoading = false
        
        switch result {
        case .success(let data):
            self.data = data
        case .failure(let error):
            self.error = error.localizedDescription
        }
    }
}
```

By following these guidelines, you can prevent threading issues in the app and ensure a smooth user experience.
