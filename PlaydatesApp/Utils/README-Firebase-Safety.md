# Firebase Safety Kit

## Overview

This document describes the Firebase Safety Kit implementation in the Playdates app, which addresses a critical issue where NSNumber to String conversion crashes were occurring at runtime.

## Problem

Firebase Firestore sometimes returns `NSNumber` objects in fields where the app expects `String` values. When string methods like `length`, `getBytes:maxLength:usedLength:encoding:options:range:remainingRange:`, `_fastCharacterContents`, `_fastCStringContents:`, or `getCharacters:range:` are called on these `NSNumber` objects, the app crashes with:

```
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', 
reason: '-[__NSCFNumber length]: unrecognized selector sent to instance...'
```

or

```
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', 
reason: '-[__NSCFNumber getBytes:maxLength:usedLength:encoding:options:range:remainingRange:]: unrecognized selector sent to instance...'
```

or

```
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', 
reason: '-[__NSCFNumber _fastCharacterContents]: unrecognized selector sent to instance...'
```

or

```
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', 
reason: '-[__NSCFNumber _fastCStringContents:]: unrecognized selector sent to instance...'
```

or

```
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', 
reason: '-[__NSCFNumber getCharacters:range:]: unrecognized selector sent to instance...'
```

## Solution: Multi-layered Data Safety

The Firebase Safety Kit provides several layers of protection to handle inconsistent data types from Firebase:

### 1. Centralized Import and Type Safety

- `ModelImports.swift` provides shared imports and type aliases
- Common Firebase types are re-exported with clear naming
- Shared utility methods ensure consistent access throughout the app

### 2. Data Sanitization at Source

Following official Firebase documentation best practices, data is sanitized immediately when retrieved from Firebase:

```swift
// Get raw data from Firebase
let rawData = document.data()
  
// IMMEDIATELY sanitize data
let data = FirebaseSafetyKit.sanitizeData(rawData) ?? [:]
  
// Use safe accessors for all field access
let name = FirebaseSafetyKit.getString(from: data, forKey: "name")
```

This pattern is used consistently across all ViewModels to ensure data integrity.

### 3. Two-Pronged Data Handling Approach

The safety system tries Firebase's built-in decoding first, then falls back to manual safe extraction:

```swift
// Try Firestore's built-in Codable support first (officially recommended)
do {
    return try document.data(as: ModelType.self)
} catch {
    // Fall back to manual parsing with safety methods
    let data = FirebaseSafetyKit.sanitizeData(document.data())
    // ... extract fields safely ...
}
```

### 4. Runtime Method Forwarding

The FirebaseSafetyKit uses Objective-C runtime capabilities to add missing string methods to NSNumber:

- Adds the `length` property to NSNumber objects to prevent common crashes
- Implements the `getBytes:maxLength:usedLength:encoding:options:range:remainingRange:` method on NSNumber
- Implements the `_fastCharacterContents` method on NSNumber to prevent crashes with string character access
- Implements the `_fastCStringContents:` method on NSNumber to prevent crashes with C string access
- Implements the `getCharacters:range:` method on NSNumber to prevent crashes with character buffer access
- Identifies other potential string methods that might need implementation
- Forwards method calls to the stringValue of the NSNumber

This approach prevents crashes when string methods are called on NSNumber objects.

### 5. Safe Accessor Methods

Type-specific accessor methods in `FirebaseSafetyKit` handle various incoming data types:

- `getString(from:forKey:defaultValue:)` - Safely extracts String values
- `getInt(from:forKey:defaultValue:)` - Safely extracts Int values
- `getDouble(from:forKey:defaultValue:)` - Safely extracts Double values
- `getBool(from:forKey:defaultValue:)` - Safely extracts Bool values
- `getDate(from:forKey:defaultValue:)` - Safely extracts Date values
- `getStringArray(from:forKey:defaultValue:)` - Safely extracts String arrays

Each method handles various incoming types appropriately.

### 6. Model Improvements

- Models implement custom `Codable` handling for robustness
- Equatable and explicit encoder implementations ensure consistent serialization
- Default values are provided for all parsed fields

## Best Practices

When working with Firebase data, follow these guidelines:

1. **Always sanitize data immediately**:
   ```swift
   let data = FirebaseSafetyKit.sanitizeData(document.data()) ?? [:]
   ```

2. **Use safe accessors for all field extractions**:
   ```swift
   let name = FirebaseSafetyKit.getString(from: data, forKey: "name") ?? "Default"
   ```

3. **Prefer FirebaseSafetyKit over direct dictionary access**:
   - ✓ `FirebaseSafetyKit.getString(from: data, forKey: "name")`
   - ✗ `data["name"] as? String`

4. **Handle nested dictionaries properly**:
   ```swift
   if let locationData = data["location"] as? [String: Any] {
       let sanitizedLocationData = FirebaseSafetyKit.sanitizeData(locationData) ?? [:]
       // ...access fields using safe accessors
   }
   ```

5. **Use Firebase transactions for atomic updates**:
   ```swift
   db.runTransaction({ (transaction, errorPointer) -> Any? {
       // ...transaction logic
   })
   ```

## Implementation References

The approach is based on Firebase documentation and best practices:

- [Firebase Add Data to Cloud Firestore](https://firebase.google.com/docs/firestore/manage-data/add-data)
- [FirebaseFirestore Swift Package](https://github.com/firebase/firebase-ios-sdk/tree/master/Firestore)

## Testing

The AppDelegate includes verification tests which run in debug mode:
- Testing NSNumber string conversion
- Testing data sanitization
- Testing safe accessors

## Maintenance

- The `ModelImports.swift` file should be imported in every ViewModel
- All new ViewModels should follow the established pattern
- When adding new models, implement robust Codable support as shown in existing models
