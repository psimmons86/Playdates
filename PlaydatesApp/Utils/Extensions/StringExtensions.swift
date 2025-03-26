import Foundation
import ObjectiveC

// MARK: - Type Safety for Any? values
extension String {
    static func safeString(from value: Any?) -> String? {
        if let string = value as? String {
            return string
        } else if let number = value as? NSNumber {
            return number.stringValue
        } else if value != nil {
            return String(describing: value!)
        }
        return nil
    }
}

// MARK: - Dictionary Extensions for safe Firebase access
extension Dictionary where Key == String, Value == Any {
    // IMPORTANT: Always convert NSNumber to String when you suspect the value
    // might be used as a string later in the code
    
    /// Get a string safely, converting other types as needed
    func safeString(for key: String) -> String? {
        guard let value = self[key] else { return nil }
        
        // If we have a number, immediately convert to string to prevent crashes later
        if let number = value as? NSNumber {
            return number.stringValue
        } else if let string = value as? String {
            return string
        } else if value is NSNull {
            return nil
        } else {
            return String(describing: value)
        }
    }
    
    /// Get an int value safely
    func safeInt(for key: String) -> Int? {
        guard let value = self[key] else { return nil }
        
        if let intValue = value as? Int {
            return intValue
        } else if let number = value as? NSNumber {
            return number.intValue
        } else if let string = value as? String, let intValue = Int(string) {
            return intValue
        } else if let double = value as? Double {
            return Int(double)
        } else if let bool = value as? Bool {
            return bool ? 1 : 0
        }
        return nil
    }
    
    /// Safely get a string array
    func safeStringArray(for key: String) -> [String]? {
        guard let value = self[key] else { return nil }
        
        if let stringArray = value as? [String] {
            return stringArray
        } else if let numberArray = value as? [NSNumber] {
            // Convert all NSNumbers to strings
            return numberArray.map { $0.stringValue }
        } else if let mixedArray = value as? [Any] {
            // Handle mixed arrays by converting each element safely
            return mixedArray.compactMap { element in
                if let string = element as? String {
                    return string
                } else if let number = element as? NSNumber {
                    return number.stringValue
                } else if element != nil {
                    return String(describing: element)
                }
                return nil
            }
        }
        return nil
    }
}

// MARK: - Firebase Field Conversion
class FirebaseTypeConverter {
    // This function helps convert any value that might be used as a string
    // later in your app. Call it IMMEDIATELY when you get data from Firebase.
    static func sanitizeValue(_ value: Any?) -> Any? {
        guard let value = value else { return nil }
        
        // If it's a number that might be used as a string later, convert it now
        if let number = value as? NSNumber {
            // Check if this is a boolean disguised as a number (Firebase does this)
            let objCType = String(cString: number.objCType)
            if objCType == "c" || objCType == "C" {
                // It's a boolean, keep it as is
                return number.boolValue
            } else {
                // It's a number - if it has a decimal, keep as a number
                if floor(number.doubleValue) != number.doubleValue {
                    return number
                } else {
                    // It's an integer-like number, which might be used as a string
                    // Convert to string immediately to avoid string-method crashes
                    return number.stringValue
                }
            }
        } else if let array = value as? [Any] {
            // Process array elements
            return array.map { sanitizeValue($0) ?? NSNull() }
        } else if let dict = value as? [String: Any] {
            // Process dictionary
            var result = [String: Any]()
            for (key, dictValue) in dict {
                result[key] = sanitizeValue(dictValue)
            }
            return result
        } else if value is NSNull {
            return nil
        }
        
        // Keep other types as is
        return value
    }
    
    // Call this function IMMEDIATELY after getting a document from Firestore
    static func sanitizeDocument(_ data: [String: Any]?) -> [String: Any]? {
        guard let data = data else { return nil }
        
        var result = [String: Any]()
        for (key, value) in data {
            result[key] = sanitizeValue(value)
        }
        return result
    }
}