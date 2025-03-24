import Foundation

/// Property wrapper to force storage of large structs on the heap
/// This helps prevent stack overflow issues in deeply nested structs
@propertyWrapper
struct StoredOnHeap<T> {
    // Using a class to force heap allocation
    private final class Box {
        var value: T
        
        init(_ value: T) {
            self.value = value
        }
    }
    
    private var box: Box
    
    init(wrappedValue: T) {
        self.box = Box(wrappedValue)
    }
    
    var wrappedValue: T {
        get { return box.value }
        set { box.value = newValue }
    }
    
    var projectedValue: StoredOnHeap<T> {
        get { return self }
        set { self = newValue }
    }
}

/// Type alias for declaring heap-stored properties more concisely
typealias HeapStored<T> = StoredOnHeap<T>

// MARK: - Codable Support for StoredOnHeap

extension StoredOnHeap: Encodable where T: Encodable {
    func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

extension StoredOnHeap: Decodable where T: Decodable {
    init(from decoder: Decoder) throws {
        let wrappedValue = try T(from: decoder)
        self.init(wrappedValue: wrappedValue)
    }
}

// MARK: - Equatable Support

extension StoredOnHeap: Equatable where T: Equatable {
    static func == (lhs: StoredOnHeap<T>, rhs: StoredOnHeap<T>) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
}

// MARK: - Hashable Support

extension StoredOnHeap: Hashable where T: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}

// MARK: - Usage Example with Optional Type

// Special implementation for Optional types to handle nil values correctly
extension StoredOnHeap where T: ExpressibleByNilLiteral {
    /// Convenience initializer that accepts nil
    init() {
        self.init(wrappedValue: nil)
    }
}

/// Helper method to convert any value to a heap-stored value
func storeOnHeap<T>(_ value: T) -> StoredOnHeap<T> {
    return StoredOnHeap(wrappedValue: value)
}

/*
 Usage examples:
 
 // Basic usage
 @StoredOnHeap var largeStruct: LargeStructType = LargeStructType()
 
 // With type alias
 @HeapStored var largeStruct: LargeStructType = LargeStructType()
 
 // With optional type
 @StoredOnHeap var optionalStruct: LargeStructType? = nil
 
 // With array of values
 @StoredOnHeap var largeArray: [LargeStructType] = []
 
 // Using the helper function
 let heapValue = storeOnHeap(myValue)
 */
