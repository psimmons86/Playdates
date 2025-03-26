import Foundation
import Firebase
import FirebaseFirestore
import ObjectiveC

/**
 A simplified safety kit to handle Firebase data type mismatches and prevent crashes.
 */
class FirebaseSafetyKit {
    
    // MARK: - Initialization and Setup
    
    /// Call this method as early as possible, ideally in AppDelegate before Firebase is configured
    static func applyRuntimeSafety() {
        print("🛠️ FirebaseSafetyKit: Initializing...")
        
        // Register an exception handler to get better diagnostic info
        NSSetUncaughtExceptionHandler { exception in
            print("⚠️ UNCAUGHT EXCEPTION: \(exception)")
            print("⚠️ Name: \(exception.name)")
            print("⚠️ Reason: \(exception.reason ?? "No reason provided")")
            print("⚠️ Stack trace: \(exception.callStackSymbols.joined(separator: "\n"))")
        }
        
        // Add the length property to NSNumber - the most common crash point
        addLengthProperty()
        
        // Set up NSNumber to forward string methods
        setupNSNumberForwarding()
        
        print("✅ FirebaseSafetyKit: Initialization complete")
    }
    
    // MARK: - Runtime Patches
    
    private static func addLengthProperty() {
        // Get the NSNumber internal class
        guard let numberClass = NSClassFromString("__NSCFNumber") else {
            print("⚠️ Could not find NSNumber internal class")
            return
        }
        
        // Check if the class already responds to length
        let selector = NSSelectorFromString("length")
        if class_respondsToSelector(numberClass, selector) {
            print("✓ NSNumber already has length property")
            return
        }
        
        // Create a C function to handle the length message
        func lengthIMP(_ self: NSObject, _: Selector) -> Int {
            return (self as! NSNumber).stringValue.count
        }
        
        // Add the method to the class
        let success = class_addMethod(
            numberClass,
            selector,
            unsafeBitCast(lengthIMP as (@convention(c) (NSObject, Selector) -> Int), to: IMP.self),
            "l@:"
        )
        
        if success {
            print("✅ Added length property to NSNumber")
        } else {
            print("❌ Failed to add length property")
        }
        
        // Add the getBytes method to prevent crashes
        let getBytesSelector = NSSelectorFromString("getBytes:maxLength:usedLength:encoding:options:range:remainingRange:")
        if class_respondsToSelector(numberClass, getBytesSelector) {
            print("✓ NSNumber already has getBytes method")
            return
        }
        
        // Create a C function to handle the getBytes message
        func getBytesIMP(_ self: NSObject, _: Selector, 
                         buffer: UnsafeMutableRawPointer?, 
                         maxLength: Int, 
                         usedLength: UnsafeMutablePointer<Int>?, 
                         encoding: UInt, 
                         options: NSString.EncodingConversionOptions, 
                         range: NSRange, 
                         remainingRange: UnsafeMutablePointer<NSRange>?) -> Bool {
            // Convert NSNumber to string and forward the call
            let stringValue = (self as! NSNumber).stringValue as NSString
            return stringValue.getBytes(buffer, maxLength: maxLength, usedLength: usedLength, 
                                       encoding: encoding, options: options, 
                                       range: range, remaining: remainingRange)
        }
        
        // Add the method to the class
        let getBytesSuccess = class_addMethod(
            numberClass,
            getBytesSelector,
            unsafeBitCast(getBytesIMP as (@convention(c) (NSObject, Selector, UnsafeMutableRawPointer?, Int, UnsafeMutablePointer<Int>?, UInt, NSString.EncodingConversionOptions, NSRange, UnsafeMutablePointer<NSRange>?) -> Bool), to: IMP.self),
            "B@:^vI^IIIr{_NSRange=QQ}^{_NSRange=QQ}"
        )
        
        if getBytesSuccess {
            print("✅ Added getBytes method to NSNumber")
        } else {
            print("❌ Failed to add getBytes method")
        }
    }
    
    private static func setupNSNumberForwarding() {
        // Since Objective-C runtime swizzling is complex in Swift, we'll use a simpler approach
        // We'll focus on data sanitization instead of trying to patch every possible string method
        print("✅ Using data sanitization approach instead of method swizzling")
        
        // Add specific string methods that are known to cause crashes
        addStringMethodsToNSNumber()
    }
    
    private static func addStringMethodsToNSNumber() {
        guard let numberClass = NSClassFromString("__NSCFNumber") else {
            print("⚠️ Could not find NSNumber internal class")
            return
        }
        
        // Add _fastCharacterContents method to prevent crashes
        let fastCharacterContentsSelector = NSSelectorFromString("_fastCharacterContents")
        if !class_respondsToSelector(numberClass, fastCharacterContentsSelector) {
            // Create a C function to handle the _fastCharacterContents message
            func fastCharacterContentsIMP(_ self: NSObject, _: Selector) -> UnsafePointer<unichar>? {
                // Convert NSNumber to string and forward the call
                let stringValue = (self as! NSNumber).stringValue as NSString
                
                // Use perform selector to call the private method on NSString
                // This is a workaround since we can't directly call _fastCharacterContents
                // We'll return nil which is safer than trying to access memory incorrectly
                return nil
            }
            
            // Add the method to the class
            let success = class_addMethod(
                numberClass,
                fastCharacterContentsSelector,
                unsafeBitCast(fastCharacterContentsIMP as (@convention(c) (NSObject, Selector) -> UnsafePointer<unichar>?), to: IMP.self),
                "^{unichar=}@:"
            )
            
            if success {
                print("✅ Added _fastCharacterContents method to NSNumber")
            } else {
                print("❌ Failed to add _fastCharacterContents method")
            }
        }
        
        // Add _fastCStringContents: method to prevent crashes
        let fastCStringContentsSelector = NSSelectorFromString("_fastCStringContents:")
        if !class_respondsToSelector(numberClass, fastCStringContentsSelector) {
            // Create a C function to handle the _fastCStringContents: message
            func fastCStringContentsIMP(_ self: NSObject, _: Selector, parameter: UnsafeMutableRawPointer?) -> UnsafePointer<Int8>? {
                // Convert NSNumber to string and forward the call
                let stringValue = (self as! NSNumber).stringValue as NSString
                
                // This is a workaround since we can't directly call _fastCStringContents:
                // We'll return nil which is safer than trying to access memory incorrectly
                return nil
            }
            
            // Add the method to the class
            let success = class_addMethod(
                numberClass,
                fastCStringContentsSelector,
                unsafeBitCast(fastCStringContentsIMP as (@convention(c) (NSObject, Selector, UnsafeMutableRawPointer?) -> UnsafePointer<Int8>?), to: IMP.self),
                "^{char=}@:^v"
            )
            
            if success {
                print("✅ Added _fastCStringContents: method to NSNumber")
            } else {
                print("❌ Failed to add _fastCStringContents: method")
            }
        }
        
        // Add getCharacters:range: method to prevent crashes
        let getCharactersSelector = NSSelectorFromString("getCharacters:range:")
        if !class_respondsToSelector(numberClass, getCharactersSelector) {
            // Create a C function to handle the getCharacters:range: message
            func getCharactersIMP(_ self: NSObject, _: Selector, buffer: UnsafeMutablePointer<unichar>, range: NSRange) {
                // Convert NSNumber to string and forward the call
                let stringValue = (self as! NSNumber).stringValue as NSString
                
                // Forward the call to the string value
                stringValue.getCharacters(buffer, range: range)
            }
            
            // Add the method to the class
            let success = class_addMethod(
                numberClass,
                getCharactersSelector,
                unsafeBitCast(getCharactersIMP as (@convention(c) (NSObject, Selector, UnsafeMutablePointer<unichar>, NSRange) -> Void), to: IMP.self),
                "v@:^S{_NSRange=QQ}"
            )
            
            if success {
                print("✅ Added getCharacters:range: method to NSNumber")
            } else {
                print("❌ Failed to add getCharacters:range: method")
            }
        }
        
        // List of common string methods that might be called on NSNumber
        let stringSelectors = [
            "substringFromIndex:",
            "substringToIndex:",
            "substringWithRange:",
            "rangeOfString:",
            "rangeOfString:options:",
            "rangeOfString:options:range:",
            "componentsSeparatedByString:",
            "stringByAppendingString:"
        ]
        
        for selectorName in stringSelectors {
            let selector = NSSelectorFromString(selectorName)
            if !class_respondsToSelector(numberClass, selector) {
                // We won't implement each method individually, but we'll log which ones
                // might need implementation if crashes continue
                print("ℹ️ NSNumber doesn't respond to \(selectorName) - might need implementation")
            }
        }
    }
    
    // MARK: - Data Sanitization
    
    /**
     Sanitizes Firebase data to prevent type issues.
     Call this IMMEDIATELY after retrieving data from Firebase.
     */
    static func sanitizeData(_ data: [String: Any]?) -> [String: Any]? {
        guard let data = data else { return nil }
        
        var result = [String: Any]()
        for (key, value) in data {
            result[key] = sanitizeValue(value)
        }
        return result
    }
    
    /**
     Recursively sanitizes a single value from Firebase.
     */
    static func sanitizeValue(_ value: Any?) -> Any? {
        guard let value = value else { return nil }
        
        // Convert NSNull to nil
        if value is NSNull {
            return nil
        }
        
        // Handle NSNumber to prevent string method crashes
        if let number = value as? NSNumber {
            // Check if it's a boolean (Firebase stores booleans as NSNumber)
            let objCType = String(cString: number.objCType)
            if objCType == "c" || objCType == "C" {
                return number.boolValue
            } else {
                // Critical fix: Convert numbers to strings to avoid crashes
                // when string methods are called on them
                return number.stringValue
            }
        }
        
        // Process arrays recursively
        if let array = value as? [Any] {
            return array.map { sanitizeValue($0) ?? NSNull() }
        }
        
        // Process dictionaries recursively
        if let dict = value as? [String: Any] {
            return sanitizeData(dict)
        }
        
        // Return other values as-is
        return value
    }
    
    // MARK: - Safe Data Access
    
    /**
     Safely extracts a String value from Firebase data.
     */
    static func getString(from data: [String: Any]?, forKey key: String, defaultValue: String? = nil) -> String? {
        guard let data = data else { return defaultValue }
        
        if let value = data[key] {
            if let string = value as? String {
                return string
            } else if let number = value as? NSNumber {
                return number.stringValue
            } else if value is NSNull {
                return defaultValue
            } else {
                return String(describing: value)
            }
        }
        
        return defaultValue
    }
    
    /**
     Safely extracts an Int value from Firebase data.
     */
    static func getInt(from data: [String: Any]?, forKey key: String, defaultValue: Int? = nil) -> Int? {
        guard let data = data else { return defaultValue }
        
        if let value = data[key] {
            if let intValue = value as? Int {
                return intValue
            } else if let doubleValue = value as? Double {
                return Int(doubleValue)
            } else if let stringValue = value as? String, let parsedInt = Int(stringValue) {
                return parsedInt
            } else if let boolValue = value as? Bool {
                return boolValue ? 1 : 0
            } else if let number = value as? NSNumber {
                return number.intValue
            }
        }
        
        return defaultValue
    }
    
    /**
     Safely extracts a Double value from Firebase data.
     */
    static func getDouble(from data: [String: Any]?, forKey key: String, defaultValue: Double? = nil) -> Double? {
        guard let data = data else { return defaultValue }
        
        if let value = data[key] {
            if let doubleValue = value as? Double {
                return doubleValue
            } else if let intValue = value as? Int {
                return Double(intValue)
            } else if let stringValue = value as? String, let parsedDouble = Double(stringValue) {
                return parsedDouble
            } else if let boolValue = value as? Bool {
                return boolValue ? 1.0 : 0.0
            } else if let number = value as? NSNumber {
                return number.doubleValue
            }
        }
        
        return defaultValue
    }
    
    /**
     Safely extracts a Bool value from Firebase data.
     */
    static func getBool(from data: [String: Any]?, forKey key: String, defaultValue: Bool = false) -> Bool {
        guard let data = data else { return defaultValue }
        
        if let value = data[key] {
            if let boolValue = value as? Bool {
                return boolValue
            } else if let intValue = value as? Int {
                return intValue != 0
            } else if let doubleValue = value as? Double {
                return doubleValue != 0
            } else if let stringValue = value as? String {
                return stringValue.lowercased() == "true" ||
                stringValue == "1" ||
                stringValue.lowercased() == "yes"
            } else if let number = value as? NSNumber {
                return number.boolValue
            }
        }
        
        return defaultValue
    }
    
    /**
     Safely extracts a Date value from Firebase data.
     */
    static func getDate(from data: [String: Any]?, forKey key: String, defaultValue: Date = Date()) -> Date {
        guard let data = data else { return defaultValue }
        
        if let value = data[key] {
            if let timestamp = value as? Timestamp {
                return timestamp.dateValue()
            } else if let date = value as? Date {
                return date
            } else if let timeInterval = value as? TimeInterval {
                return Date(timeIntervalSince1970: timeInterval)
            } else if let stringValue = value as? String {
                // Try to parse common date formats
                let dateFormatter = DateFormatter()
                
                // Try ISO8601 format
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                if let date = dateFormatter.date(from: stringValue) {
                    return date
                }
                
                // Try simple date format
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let date = dateFormatter.date(from: stringValue) {
                    return date
                }
            }
        }
        
        return defaultValue
    }
    
    /**
     Safely extracts an array of Strings from Firebase data.
     */
    static func getStringArray(from data: [String: Any]?, forKey key: String, defaultValue: [String]? = nil) -> [String]? {
        guard let data = data else { return defaultValue }
        
        if let array = data[key] as? [Any] {
            return array.compactMap { value -> String? in
                if let string = value as? String {
                    return string
                } else if let number = value as? NSNumber {
                    return number.stringValue
                } else if value is NSNull {
                    return nil
                } else {
                    return String(describing: value)
                }
            }
        }
        
        return defaultValue
    }
    
    /**
     Safely handles DocumentSnapshot conversion to a dictionary.
     */
    static func parseDocument(_ document: DocumentSnapshot?) -> [String: Any]? {
        guard let document = document, document.exists,
              let data = document.data() else { return nil }
        
        return sanitizeData(data)
    }
}

// MARK: - Dictionary Extensions

extension Dictionary where Key == String, Value == Any {
    /**
     Sanitizes all values in the dictionary to prevent Firebase type issues.
     */
    func sanitized() -> [String: Any] {
        return FirebaseSafetyKit.sanitizeData(self) ?? [:]
    }
    
    /**
     Safely extracts a String value from the dictionary.
     */
    func safeString(for key: String, defaultValue: String? = nil) -> String? {
        return FirebaseSafetyKit.getString(from: self, forKey: key, defaultValue: defaultValue)
    }
    
    /**
     Safely extracts an Int value from the dictionary.
     */
    func safeInt(for key: String, defaultValue: Int? = nil) -> Int? {
        return FirebaseSafetyKit.getInt(from: self, forKey: key, defaultValue: defaultValue)
    }
    
    /**
     Safely extracts a Double value from the dictionary.
     */
    func safeDouble(for key: String, defaultValue: Double? = nil) -> Double? {
        return FirebaseSafetyKit.getDouble(from: self, forKey: key, defaultValue: defaultValue)
    }
    
    /**
     Safely extracts a Bool value from the dictionary.
     */
    func safeBool(for key: String, defaultValue: Bool = false) -> Bool {
        return FirebaseSafetyKit.getBool(from: self, forKey: key, defaultValue: defaultValue)
    }
    
    /**
     Safely extracts a Date value from the dictionary.
     */
    func safeDate(for key: String, defaultValue: Date = Date()) -> Date {
        return FirebaseSafetyKit.getDate(from: self, forKey: key, defaultValue: defaultValue)
    }
    
    /**
     Safely extracts an array of Strings from the dictionary.
     */
    func safeStringArray(for key: String, defaultValue: [String]? = nil) -> [String]? {
        return FirebaseSafetyKit.getStringArray(from: self, forKey: key, defaultValue: defaultValue)
    }
}
