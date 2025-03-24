# API Connection Debugging Guide

This guide provides instructions for debugging API connection issues in the Playdates app, particularly with the Google Places API and Firebase.

## Debugging Tools Added

We've added several debugging tools to help diagnose API connection issues:

### 1. Activity Search Debugging

In `ActivitySearchViewModel.swift`, we've added debug logging to:
- Track when location is nil during searches
- Log search queries and coordinates
- Log API response counts
- Log API errors

```swift
func searchActivities() {
    guard !searchQuery.isEmpty else {
        error = "Please enter an activity type to search for"
        return
    }
    
    guard let location = locationManager.location else {
        error = "Location not available. Please enable location services."
        print("Debug: Location is nil when searching")
        return
    }
    
    print("Debug: Searching for '\(searchQuery)' at location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    // ... rest of the method
}
```

### 2. Location Services Debugging

In `ActivitySearchView.swift`, we've added debug logging in the `onAppear` method to:
- Check the authorization status of the location manager
- Verify if a location is available
- Log the current coordinates if available

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

### 3. Network Request Debugging

In `GooglePlacesService.swift`, we've added debug logging to:
- Log the full URL of API requests
- Track when requests are made

```swift
print("Debug: Making Places API request to URL: \(url)")
```

## Common Issues and Solutions

### Location Services Issues

If you see "Location is nil when searching" in the logs:

1. Check if location services are enabled on the device
2. Verify the app has location permissions
3. Check the authorization status in the logs
4. Make sure the app has been granted "While Using" or "Always" permission

### Google Places API Issues

If API requests are being made but returning no results:

1. Check the API key in `GooglePlacesService.swift`
2. Verify the search radius (default is 5000 meters)
3. Try different search terms
4. Check if the API request URL is properly formatted in the logs
5. Verify the API key has the proper permissions and is enabled for the Places API

### Firebase Issues

If you're experiencing "Missing or insufficient privileges" errors:

1. Follow the instructions in `Firebase-Permissions-README.md`
2. Update your Firebase security rules to allow read access to the activities collection
3. Check the Firebase console for any quota limits or API restrictions

## How to Use the Debug Logs

1. Run the app in debug mode
2. Open the Xcode console to view the logs
3. Perform the action that's failing (e.g., search for activities)
4. Look for "Debug:" prefixed messages in the console
5. Check for error messages or unexpected values

## Next Steps for Debugging

If the basic debugging doesn't resolve the issue:

1. Try using the app on a different device or simulator
2. Check network connectivity
3. Verify API quotas and limits
4. Use a tool like Charles Proxy to inspect the raw API requests and responses
5. Check for any firewall or network restrictions that might be blocking API requests

## API Documentation

- [Google Places API Documentation](https://developers.google.com/maps/documentation/places/web-service/overview)
- [Firebase Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
