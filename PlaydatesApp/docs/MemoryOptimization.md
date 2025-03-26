# Memory Optimization in PlaydatesApp

## Background: Stack Overflow Issues

The application was experiencing `EXC_BAD_ACCESS` crashes, particularly when handling large Swift value types (structs). This is a common issue in Swift applications that deal with complex data models. The error occurs because:

1. Swift value types (structs) are stored on the stack by default
2. The stack has limited memory compared to the heap
3. Deep nesting, large collections, or complex struct hierarchies can exceed stack limits
4. This leads to stack overflow and crashes (`EXC_BAD_ACCESS`)

## Solution: The StoredOnHeap Property Wrapper

We've implemented a property wrapper called `StoredOnHeap` that forces storage of large value types on the heap instead of the stack. This is an elegant approach that:

1. Prevents stack overflow by using the larger memory space of the heap
2. Maintains the value semantics of the structs
3. Is type-safe and preserves the original API surface
4. Requires minimal changes to existing code

### How It Works

The `StoredOnHeap` wrapper works by:
1. Wrapping the value type in an array (arrays are always heap-allocated in Swift)
2. Providing transparent access to the wrapped value through getters and setters
3. Maintaining reference semantics internally while preserving value semantics externally

```swift
@propertyWrapper
struct StoredOnHeap<T> {
    private var value: [T]  // Arrays are reference types, stored on the heap
    
    init(wrappedValue: T) {
        self.value = [wrappedValue]
    }
    
    var wrappedValue: T {
        get { return value[0] }
        set { value[0] = newValue }
    }
}
```

## Applied Optimizations

We've applied this pattern to several key data structures in the app:

1. `User` model - Storing large child collections on the heap
2. `Activity` model - Storing `Location` and collections on the heap
3. `Playdate` model - Storing `Location` and attendee lists on the heap

For each optimized model, we're wrapping potentially large properties with `@StoredOnHeap`:

```swift
struct User: Identifiable, Codable {
    // Regular properties
    @DocumentID var id: String?
    var name: String
    
    // Heap-stored properties
    @StoredOnHeap var children: [Child]?
    @StoredOnHeap var friendIDs: [String]?
    // ...
}
```

## Additional Changes

1. **Import Updates**: Added proper imports in `ModelImports.swift` to make the `StoredOnHeap` type available throughout the app
2. **Syntax Fixes**: Fixed syntax issues with missing commas between parameters
3. **Type Aliases**: Added a convenient type alias `HeapStored` for shorter declarations
4. **Modern Swift**: Updated to use the modern SwiftUI application lifecycle with `@main` and `UIApplicationDelegateAdaptor`

## Integration Test Notes

After implementing these changes:

1. Large model objects should now properly deserialize without stack overflow
2. Complex nested structures should maintain their value semantics while being stored safely
3. Collection processing should be more robust when dealing with larger datasets

## Troubleshooting

If stack-related crashes still occur:

1. Identify the largest struct types in your models
2. Apply `@StoredOnHeap` to properties that contain large collections or complex nested structures
3. Ensure proper initialization of the wrapped properties in all constructors
4. Consider breaking down overly complex structures into smaller components
