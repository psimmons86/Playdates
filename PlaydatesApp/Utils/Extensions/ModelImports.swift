import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import Combine
import CoreLocation
import MapKit
import Combine
import SwiftUI
import MapKit

// Re-export common Firebase types with clear naming
typealias FirebaseTimestamp = Timestamp
typealias FirebaseDocumentID = DocumentID
typealias FirebaseDocumentReference = DocumentReference
typealias FirebaseDocumentSnapshot = DocumentSnapshot
typealias FirebaseQueryDocumentSnapshot = QueryDocumentSnapshot
typealias FirebaseListenerRegistration = ListenerRegistration

// Shared utility types
typealias OptionalString = String?
typealias StringArray = [String]
typealias Dictionary = [String: Any]

// Common result type for async operations
typealias FirebaseResult<T> = Result<T, Error>

// Note: HeapStored typealias is defined in StoredOnHeap.swift
