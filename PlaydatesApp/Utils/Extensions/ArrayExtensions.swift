import Foundation

extension Array {
    /// Splits the array into chunks of a specified size.
    /// - Parameter size: The maximum size of each chunk.
    /// - Returns: An array of arrays, where each inner array is a chunk of the original.
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] } // Avoid division by zero or infinite loop
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
