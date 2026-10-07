import Foundation

/// Bounded per-category history. Automatic edits cannot consume Manual's capacity.
/// A global Reset is undoable until another category edit starts.
struct ScopedUndoHistory<Category: Hashable, Snapshot> {
    private var entries: [(category: Category?, snapshot: Snapshot)] = []
    private let capacity: Int
    init(capacity: Int = 30) { precondition(capacity > 0); self.capacity = capacity }
    mutating func append(_ snapshot: Snapshot, for category: Category?) {
        if category != nil { entries.removeAll { $0.category == nil } }
        entries.append((category, snapshot))
        let indices = entries.indices.filter { entries[$0].category == category }
        if indices.count > capacity { entries.remove(at: indices[0]) }
    }
    func canUndo(_ category: Category?) -> Bool {
        entries.contains { $0.category == category || $0.category == nil }
    }
    mutating func pop(for category: Category?) -> Snapshot? {
        guard let index = entries.lastIndex(where: { $0.category == category || $0.category == nil }) else { return nil }
        return entries.remove(at: index).snapshot
    }
}

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
