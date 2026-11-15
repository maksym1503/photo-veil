import Foundation
import CoreFoundation

/// Preparation only: this model neither records usage nor gates the V4 editor.
struct CommerceConfiguration: Equatable, Sendable {
    let monthlyProductID: String
    let freePhotoLimit: Int

    static func load(bundle: Bundle = .main) -> CommerceConfiguration? {
        guard let url = bundle.url(forResource: "VeilCommerce", withExtension: "plist"),
              let data = try? Data(contentsOf: url) else { return nil }
        return parse(data)
    }
    static func parse(_ data: Data) -> CommerceConfiguration? {
        guard let fields = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let enabled = fields["PurchasesEnabled"] as? NSNumber,
              CFGetTypeID(enabled) == CFBooleanGetTypeID(), enabled.boolValue,
              let id = fields["MonthlyProductID"] as? String, !id.isEmpty,
              id == id.trimmingCharacters(in: .whitespacesAndNewlines),
              id.contains("."), id.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "." || $0 == "_" || $0 == "-") }),
              let number = fields["FreePhotoLimit"] as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(),
              let count = fields["FreePhotoLimit"] as? Int, (1...10).contains(count) else { return nil }
        return CommerceConfiguration(monthlyProductID: id, freePhotoLimit: count)
    }
}

enum ProposedPhotoAllowance {
    enum Access: Equatable { case existingSession, subscriber, freePhoto, subscriptionRequired }
    /// Usage must eventually be recorded by successful export session, never by gallery count.
    static func access(limit: Int, completedSessions: Int, alreadyExportedSession: Bool, subscribed: Bool) -> Access {
        if alreadyExportedSession { return .existingSession }
        if subscribed { return .subscriber }
        return max(0, completedSessions) < max(0, limit) ? .freePhoto : .subscriptionRequired
    }
}

/// Successful output operations, never image identity or editing-session identity.
/// Main-actor confinement makes admission and completion atomic within the app.
@MainActor final class ExportAllowance {
    enum Failure: Error, Equatable { case busy, subscriptionRequired, storageUnavailable }
    private let read: () throws -> ExportUsageRecord
    private let write: (ExportUsageRecord) throws -> Void
    private var record: ExportUsageRecord?
    private var dirty = false
    private var active: (id: UUID, free: Bool)?
    var limit: Int { record?.limit ?? 1 }
    var completed: Int? { record?.completed }
    var effectiveLimit: Int? { record?.limit }
    var currentRecord: ExportUsageRecord? { record }
    init(read: @escaping () throws -> ExportUsageRecord, write: @escaping (ExportUsageRecord) throws -> Void) {
        self.read = read; self.write = write
    }
    /// Read-only presentation load; preserve dirty successful usage in memory.
    func loadSnapshot() throws -> Int {
        if let record { return record.completed }
        do {
            let loaded = try read()
            record = loaded
            return loaded.completed
        } catch { throw Failure.storageUnavailable }
    }
    func begin(subscribed: Bool) throws -> UUID {
        guard active == nil else { throw Failure.busy }
        if !subscribed {
            do {
                if record == nil { record = try read() }
                guard let record else { throw Failure.storageUnavailable }
                // Probe availability; also retries a dirty success before granting more uses.
                try write(record); dirty = false
                guard record.completed < record.limit else { throw Failure.subscriptionRequired }
            } catch let error as Failure { throw error }
            catch { throw Failure.storageUnavailable }
        }
        let id = UUID(); active = (id, !subscribed); return id
    }
    /// A completed save stays successful even when bookkeeping is temporarily unavailable.
    /// Return false only to request a separate usage-storage warning.
    @discardableResult func finish(_ id: UUID, succeeded: Bool) -> Bool {
        guard let lease = active, lease.id == id else { return true }
        active = nil
        guard succeeded, lease.free else { return true }
        guard let current = record else { return false }
        record = ExportUsageRecord(completed: min(current.limit, current.completed + 1), limit: current.limit)
        dirty = true
        do { try write(record!); dirty = false; return true }
        catch { return false }
    }
}

struct ExportUsageRecord: Codable, Equatable {
    let version: Int
    let completed: Int
    let limit: Int
    init(completed: Int, limit: Int = 1) { version = 2; self.completed = completed; self.limit = limit }
    static func decode(_ data: Data) throws -> ExportUsageRecord {
        let invalid = ExportAllowance.Failure.storageUnavailable
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let version = object["version"] as? Int,
              object.values.allSatisfy({ value in
                  guard let number = value as? NSNumber else { return false }
                  return CFGetTypeID(number) != CFBooleanGetTypeID()
              }) else { throw invalid }
        if version == 1 {
            guard Set(object.keys) == ["version", "completed"], let completed = object["completed"] as? Int, (0...2).contains(completed) else { throw invalid }
            return ExportUsageRecord(completed: completed, limit: 2)
        }
        guard version == 2, Set(object.keys) == ["version", "completed", "limit"],
              let completed = object["completed"] as? Int, let limit = object["limit"] as? Int,
              [1, 2].contains(limit), (0...limit).contains(completed) else { throw invalid }
        return ExportUsageRecord(completed: completed, limit: limit)
    }
}

/// Pure presentation policy: never advertise a trial based on local purchase history.
enum SubscriptionOfferPolicy {
    static func hasThreeDayTrial(eligible: Bool, freeTrial: Bool, days: Int?) -> Bool {
        eligible && freeTrial && days == 3
    }
    static func yearlySavings(monthly: Decimal, yearly: Decimal) -> Int? {
        guard monthly > 0, yearly > 0, yearly < monthly * 12 else { return nil }
        let ratio = NSDecimalNumber(decimal: (1 - yearly / (monthly * 12)) * 100).doubleValue
        return Int(ratio.rounded())
    }
}

/// Invalidates suspended preparation when its presenting view leaves the hierarchy.
/// Once an activity is presented, its completion owns the lease instead.
@MainActor final class ExportPreparationLifetime {
    private(set) var generation = UUID()
    func invalidate() { generation = UUID() }
    func contains(_ request: UUID) -> Bool { generation == request }
}

/// UI disappearance is not an outcome. Only the activity completion releases admission.
@MainActor final class ShareExportCompletion {
    private var delivered = false
    private let completion: (Bool) -> Void
    init(completion: @escaping (Bool) -> Void) { self.completion = completion }
    func finish(completed: Bool, hasError: Bool) {
        guard !delivered else { return }
        delivered = true; completion(completed && !hasError)
    }
}


extension Notification.Name {
    static let veilPreviewAccessInvalidated = Notification.Name("VeilPreviewAccessInvalidated")
}

enum PreviewEntitlement: Equatable { case unknown, free, pro }
enum PremiumPreviewState: Equatable {
    case clean, checking, exhausted, unavailable
    var marked: Bool { self == .exhausted }
    var protectsPhoto: Bool { self == .checking || self == .unavailable }
    static func resolve(completed: Int?, limit: Int, entitlement: PreviewEntitlement) -> Self {
        if entitlement == .pro { return .clean }
        if let completed, completed >= 0, completed < limit { return .clean }
        if entitlement == .unknown { return .checking }
        guard let completed, completed >= 0 else { return .unavailable }
        return .exhausted
    }
}

/// Invalidations outlive a suspended StoreKit scan, including app backgrounding.
struct PreviewEntitlementEpoch {
    private(set) var value: UInt64 = 0
    mutating func invalidate() { value &+= 1 }
    func accepts(_ request: UInt64) -> Bool { request == value }
}
