import Foundation

extension String {
    /// Returns `fallback` if the string is empty; otherwise returns self.
    func ifEmpty(_ fallback: String) -> String { self.isEmpty ? fallback : self }
}
