# Google Maps API Guide for Playdates App

This guide explains how to properly configure and use the Google Maps API in the Playdates app.

## API Configuration

The app uses the following Google Maps APIs:

1. **Google Places API** - For finding nearby activities and points of interest
2. **Maps SDK for iOS** - For displaying maps and location data
3. **Geocoding API** - For converting addresses to coordinates and vice versa

## API Key Configuration

The Google Maps API key has been added to the Info.plist file with the key `GMSApiKey`:

```xml
<key>GMSApiKey</key>
<string>AIzaSyBLEgfEKCQbkMR4kCgy77bGOJVcTwPv7iI</string>
```

This key is used by the GooglePlacesService to make API requests.

## Enabling APIs in Google Cloud Console

To ensure all required APIs are enabled:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to "APIs & Services" > "Library"
4. Search for and enable each of these APIs:
   - "Places API"
   - "Maps SDK for iOS"
   - "Geocoding API"

## API Key Restrictions

For security, you should restrict your API key:

1. Go to "APIs & Services" > "Credentials"
2. Find your API key and click "Edit"
3. Under "Application restrictions", restrict it to iOS apps
4. Under "API restrictions", restrict it to only the APIs you've enabled
5. Add your app's bundle ID (com.example.playdates) to the allowed applications

## Implementation Details

### GooglePlacesService

The `GooglePlacesService` class handles all interactions with the Google Places API:

- `searchNearbyActivities` - Searches for activities near a location
- `getPlaceDetails` - Gets detailed information about a specific place
- `getPhotoURL` - Constructs a URL for a place photo
- `loadPhoto` - Loads a photo for a place

### ActivityViewModel Integration

The `ActivityViewModel` uses the GooglePlacesService to fetch nearby activities:

- `fetchNearbyActivities(location:)` - Fetches activities near a CLLocation
- `fetchNearbyActivities(latitude:longitude:)` - Fallback method using raw coordinates

### ExploreView Integration

The `ExploreView` has been updated to:

1. Fetch activities from both Firebase and Google Places API
2. Combine results from both sources
3. Display the combined results in the UI

## Troubleshooting

If you encounter issues with the Google Maps API:

1. **No activities found**: 
   - Check if location permissions are granted
   - Verify the API key is correct in Info.plist
   - Ensure all required APIs are enabled in Google Cloud Console
   - Check the console for error messages

2. **API key issues**:
   - Verify the key is correctly added to Info.plist
   - Check if the key has the proper API restrictions
   - Ensure the key is active in Google Cloud Console

3. **Location issues**:
   - Check if location services are enabled on the device
   - Verify the app has location permissions
   - Check the LocationManager for error messages

## Debug Logging

Debug logging has been added to help diagnose issues:

- Location service status is logged in ExploreView's onAppear
- API requests are logged in GooglePlacesService
- Error messages are captured and displayed in the UI

## API Usage Limits

Be aware of Google Maps API usage limits:

- The Places API has a free tier of $200 worth of usage per month
- Beyond that, charges apply based on the number of API calls
- Consider implementing caching to reduce API calls (already implemented in GooglePlacesService)

## Further Resources

- [Google Maps Platform Documentation](https://developers.google.com/maps/documentation)
- [Places API Documentation](https://developers.google.com/maps/documentation/places/web-service/overview)
- [Maps SDK for iOS Documentation](https://developers.google.com/maps/documentation/ios-sdk/overview)
