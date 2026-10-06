import Foundation

/// Analysis is cached independently of the user's current activation intent.
/// Shared by Faces, Plates, Documents and Background (one mask = one region).
struct DetectedPrivacySelection: Equatable {
    enum Status: Equatable {
        case idle, detecting, completed(Int), failed
    }
    private(set) var status: Status = .idle
    var selected = Set<Int>()
    private var activationRequested = false

    var hasAnalyzed: Bool {
        switch status { case .completed, .failed: true; default: false }
    }
    var isActive: Bool { !selected.isEmpty }
    /// Editing focus alone is not an undoable change. A new request or cached
    /// activation that changes selection is; its analysis remains independently cached.
    var needsActivationUndo: Bool {
        switch status {
        case .idle, .detecting: !activationRequested
        case .completed(let count): selected != Set(0..<count)
        case .failed: false
        }
    }
    mutating func activate() {
        activationRequested = true
        if case .completed(let count) = status { selected = Set(0..<count) }
    }
    mutating func begin() { status = .detecting }
    mutating func complete(count: Int) {
        status = .completed(count)
        selected = activationRequested ? Set(0..<count) : []
    }
    mutating func fail() { status = .failed; selected = [] }
    mutating func clear() { activationRequested = false; selected = [] }

    /// Undo restores activation intent as well as selection, without discarding analysis.
    mutating func restoreSelection(_ indices: Set<Int>) {
        activationRequested = !indices.isEmpty
        selected = indices
    }

    func feedback(for category: String) -> String? {
        switch status {
        case .completed(0): "No \(category) detected. Try Manual."
        case .failed: "Couldn’t detect \(category). Try Manual."
        default: nil
        }
    }
}
