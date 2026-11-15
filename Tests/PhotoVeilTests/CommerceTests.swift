import XCTest
@testable import ImageGeometry

final class CommerceTests: XCTestCase {
    func testPreviewPolicyUsesActualAllowanceAndVerifiedPro() {
        XCTAssertFalse(PremiumPreviewState.unavailable.marked)
        XCTAssertTrue(PremiumPreviewState.unavailable.protectsPhoto)
        XCTAssertFalse(PremiumPreviewState.checking.marked)
        XCTAssertTrue(PremiumPreviewState.checking.protectsPhoto)
        XCTAssertTrue(PremiumPreviewState.exhausted.marked)
        XCTAssertFalse(PremiumPreviewState.exhausted.protectsPhoto)
        XCTAssertFalse(PremiumPreviewState.clean.marked)
        XCTAssertFalse(PremiumPreviewState.clean.protectsPhoto)
        for limit in [1, 2] {
            for count in 0...2 {
                XCTAssertEqual(PremiumPreviewState.resolve(completed: count, limit: limit, entitlement: .free), count < limit ? .clean : .exhausted)
                XCTAssertEqual(PremiumPreviewState.resolve(completed: count, limit: limit, entitlement: .pro), .clean)
                XCTAssertEqual(PremiumPreviewState.resolve(completed: count, limit: limit, entitlement: .unknown), count < limit ? .clean : .checking)
            }
        }
        XCTAssertEqual(PremiumPreviewState.resolve(completed: nil, limit: 2, entitlement: .free), .unavailable)
        XCTAssertEqual(PremiumPreviewState.resolve(completed: nil, limit: 2, entitlement: .unknown), .checking)
        XCTAssertEqual(PremiumPreviewState.resolve(completed: nil, limit: 2, entitlement: .pro), .clean)
    }
    func testPreviewEpochRejectsScansFromBeforeBackgroundAndNewerRefresh() {
        var gate = PreviewEntitlementEpoch()
        let beforeBackground = gate.value
        gate.invalidate()
        XCTAssertFalse(gate.accepts(beforeBackground))
        let firstForeground = gate.value
        gate.invalidate()
        XCTAssertFalse(gate.accepts(firstForeground))
        XCTAssertTrue(gate.accepts(gate.value))
    }
    @MainActor func testReadOnlyPreviewLoadPreservesDirtySuccessfulUsage() throws {
        var persisted = ExportUsageRecord(completed: 0, limit: 1), writes = 0, fail = false
        let gate = ExportAllowance(read: { persisted }, write: { value in
            writes += 1
            if fail { throw ExportAllowance.Failure.storageUnavailable }
            persisted = value
        })
        XCTAssertEqual(try gate.loadSnapshot(), 0)
        XCTAssertEqual(writes, 0, "Preview observation cannot consume or create usage")
        let lease = try gate.begin(subscribed: false)
        fail = true
        XCTAssertFalse(gate.finish(lease, succeeded: true))
        XCTAssertEqual(persisted.completed, 0)
        XCTAssertEqual(try gate.loadSnapshot(), 1, "Never replace dirty success with old persisted value")
    }
    @MainActor func testPreviewStorageFailureDoesNotInventAFreeAllowance() throws {
        let gate = ExportAllowance(read: { throw ExportAllowance.Failure.storageUnavailable }, write: { _ in XCTFail("A read-only load must not write") })
        XCTAssertThrowsError(try gate.loadSnapshot())
        XCTAssertNil(gate.completed)
    }

    @MainActor func testDepartedGalleryPreparationReleasesUnpresentedLease() async throws {
        var count = ExportUsageRecord(completed: 0)
        let gate = ExportAllowance(read: { count }, write: { count = $0 })
        let lifetime = ExportPreparationLifetime()
        let request = lifetime.generation
        let lease = try gate.begin(subscribed: false)
        // Model navigation away while asynchronous photo preparation is suspended.
        let shouldPresent = await withCheckedContinuation { continuation in
            Task { @MainActor in
                lifetime.invalidate()
                continuation.resume(returning: lifetime.contains(request))
            }
        }
        XCTAssertFalse(shouldPresent)
        if !shouldPresent { gate.finish(lease, succeeded: false) }
        XCTAssertEqual(count.completed, 0)
        XCTAssertTrue(gate.finish(try gate.begin(subscribed: false), succeeded: true))
        XCTAssertEqual(count.completed, 1)
    }
    @MainActor func testTwoSuccessesThenPaywallAndDuplicateCompletion() throws {
        var persisted = ExportUsageRecord(completed: 0, limit: 2)
        let gate = ExportAllowance(read: { persisted }, write: { persisted = $0 })
        for expected in 1...2 {
            let lease = try gate.begin(subscribed: false)
            XCTAssertTrue(gate.finish(lease, succeeded: true))
            XCTAssertTrue(gate.finish(lease, succeeded: true))
            XCTAssertEqual(persisted.completed, expected)
        }
        XCTAssertThrowsError(try gate.begin(subscribed: false)) { XCTAssertEqual($0 as? ExportAllowance.Failure, .subscriptionRequired) }
        let restarted = ExportAllowance(read: { persisted }, write: { persisted = $0 })
        XCTAssertThrowsError(try restarted.begin(subscribed: false))
    }
    @MainActor func testFailedAndCancelledExportsDoNotConsumeAndLeaseIsExclusive() throws {
        var persisted = ExportUsageRecord(completed: 0, limit: 2)
        let gate = ExportAllowance(read: { persisted }, write: { persisted = $0 })
        for _ in 0..<4 {
            let lease = try gate.begin(subscribed: false)
            XCTAssertThrowsError(try gate.begin(subscribed: true)) { XCTAssertEqual($0 as? ExportAllowance.Failure, .busy) }
            gate.finish(UUID(), succeeded: true)
            XCTAssertThrowsError(try gate.begin(subscribed: false))
            gate.finish(lease, succeeded: false)
            XCTAssertEqual(persisted.completed, 0)
        }
        gate.finish(try gate.begin(subscribed: false), succeeded: true)
        XCTAssertEqual(persisted.completed, 1)
    }
    @MainActor func testProDoesNotConsumeRemainingFreeUsesAndExpiryRestoresLimit() throws {
        var persisted = ExportUsageRecord(completed: 1, limit: 2)
        let gate = ExportAllowance(read: { persisted }, write: { persisted = $0 })
        for _ in 0..<10 { gate.finish(try gate.begin(subscribed: true), succeeded: true) }
        XCTAssertEqual(persisted.completed, 1)
        gate.finish(try gate.begin(subscribed: false), succeeded: true)
        XCTAssertEqual(persisted.completed, 2)
        XCTAssertThrowsError(try gate.begin(subscribed: false))
        gate.finish(try gate.begin(subscribed: true), succeeded: true)
        XCTAssertEqual(persisted.completed, 2)
    }
    @MainActor func testStorageFailureNeverResetsAllowanceAndSuccessRetriesDirtyCount() throws {
        var persisted = ExportUsageRecord(completed: 0, limit: 2), unavailable = true
        let gate = ExportAllowance(read: { if unavailable { throw ExportAllowance.Failure.storageUnavailable }; return persisted },
                                   write: { if unavailable { throw ExportAllowance.Failure.storageUnavailable }; persisted = $0 })
        XCTAssertThrowsError(try gate.begin(subscribed: false))
        unavailable = false
        let lease = try gate.begin(subscribed: false)
        unavailable = true
        XCTAssertFalse(gate.finish(lease, succeeded: true))
        XCTAssertEqual(gate.completed, 1)
        XCTAssertThrowsError(try gate.begin(subscribed: false))
        unavailable = false
        let next = try gate.begin(subscribed: false)
        XCTAssertEqual(persisted.completed, 1)
        gate.finish(next, succeeded: true)
        XCTAssertEqual(persisted.completed, 2)
    }
    @MainActor func testProCanExportWhenLocalUsageStorageIsLocked() throws {
        let gate = ExportAllowance(read: { throw ExportAllowance.Failure.storageUnavailable }, write: { _ in throw ExportAllowance.Failure.storageUnavailable })
        XCTAssertTrue(gate.finish(try gate.begin(subscribed: true), succeeded: true))
        XCTAssertThrowsError(try gate.begin(subscribed: false))
    }
    @MainActor func testShareDisappearanceBeforeCompletionAndDuplicateCallback() throws {
        var count = ExportUsageRecord(completed: 0, limit: 2)
        let gate = ExportAllowance(read: { count }, write: { count = $0 })
        let lease = try gate.begin(subscribed: false)
        let completion = ShareExportCompletion { gate.finish(lease, succeeded: $0) }
        // SwiftUI disappearance performs cleanup only; the activity still owns admission.
        XCTAssertThrowsError(try gate.begin(subscribed: false))
        completion.finish(completed: true, hasError: false)
        completion.finish(completed: false, hasError: false)
        completion.finish(completed: true, hasError: false)
        XCTAssertEqual(count.completed, 1)
        let cancelled = try gate.begin(subscribed: false)
        ShareExportCompletion { gate.finish(cancelled, succeeded: $0) }.finish(completed: false, hasError: false)
        XCTAssertEqual(count.completed, 1)
        let failed = try gate.begin(subscribed: false)
        ShareExportCompletion { gate.finish(failed, succeeded: $0) }.finish(completed: true, hasError: true)
        XCTAssertEqual(count.completed, 1)
    }
    func testUsageRecordRejectsCorruptionUnknownVersionAndOutOfBounds() throws {
        for count in 0...2 {
            XCTAssertEqual(try ExportUsageRecord.decode(Data("{\"version\":1,\"completed\":\(count)}".utf8)), ExportUsageRecord(completed: count, limit: 2))
        }
        XCTAssertEqual(ExportUsageRecord(completed: 0), ExportUsageRecord(completed: 0, limit: 1), "A missing ledger starts with one free export")
        XCTAssertEqual(try ExportUsageRecord.decode(JSONEncoder().encode(ExportUsageRecord(completed: 1, limit: 1))), ExportUsageRecord(completed: 1, limit: 1))
        for text in ["{\"version\":true,\"completed\":0}", "{\"version\":2,\"completed\":true,\"limit\":1}", "{\"version\":2,\"completed\":0,\"limit\":true}", "{}", "not-json", "{\"version\":2,\"completed\":0}", "{\"version\":1,\"completed\":-1}", "{\"version\":1,\"completed\":3}", "{\"version\":2,\"completed\":2,\"limit\":1}", "{\"version\":2,\"completed\":0,\"limit\":3}"] {
            XCTAssertThrowsError(try ExportUsageRecord.decode(Data(text.utf8)))
        }
    }
    @MainActor func testLegacyMigrationProbePreservesEveryRecordedCountAndLimit() throws {
        for used in 0...2 {
            var bytes = Data("{\"version\":1,\"completed\":\(used)}".utf8)
            let original = bytes
            var failedWrite = true
            let gate = ExportAllowance(read: { try ExportUsageRecord.decode(bytes) }, write: { value in
                if failedWrite { throw ExportAllowance.Failure.storageUnavailable }
                bytes = try JSONEncoder().encode(value)
            })
            XCTAssertEqual(try gate.loadSnapshot(), used)
            XCTAssertEqual(gate.limit, 2)
            XCTAssertEqual(bytes, original, "Preview cannot migrate persistence")
            XCTAssertThrowsError(try gate.begin(subscribed: false))
            XCTAssertEqual(bytes, original, "Failed migration cannot overwrite history")
            failedWrite = false
            if used < 2 {
                let lease = try gate.begin(subscribed: false)
                XCTAssertEqual(try ExportUsageRecord.decode(bytes), ExportUsageRecord(completed: used, limit: 2))
                gate.finish(lease, succeeded: true)
                XCTAssertEqual(try ExportUsageRecord.decode(bytes).completed, used + 1)
            } else {
                XCTAssertThrowsError(try gate.begin(subscribed: false))
            }
            let restarted = ExportAllowance(read: { try ExportUsageRecord.decode(bytes) }, write: { bytes = try JSONEncoder().encode($0) })
            XCTAssertEqual(try restarted.loadSnapshot(), min(2, used + 1))
            XCTAssertEqual(restarted.limit, 2)
        }
    }
    @MainActor func testNewOneExportCancellationProAndDirtySuccessNeverGrantSecondUse() throws {
        var persisted = ExportUsageRecord(completed: 0)
        var failedWrite = false
        let gate = ExportAllowance(read: { persisted }, write: {
            if failedWrite { throw ExportAllowance.Failure.storageUnavailable }
            persisted = $0
        })
        XCTAssertEqual(try gate.loadSnapshot(), 0); XCTAssertEqual(gate.limit, 1)
        let cancelled = try gate.begin(subscribed: false)
        XCTAssertThrowsError(try gate.begin(subscribed: true))
        gate.finish(cancelled, succeeded: false)
        for _ in 0..<3 { gate.finish(try gate.begin(subscribed: true), succeeded: true) }
        XCTAssertEqual(persisted.completed, 0)
        let success = try gate.begin(subscribed: false)
        failedWrite = true
        XCTAssertFalse(gate.finish(success, succeeded: true))
        gate.finish(success, succeeded: true)
        XCTAssertEqual(gate.completed, 1)
        XCTAssertThrowsError(try gate.begin(subscribed: false))
        failedWrite = false
        XCTAssertThrowsError(try gate.begin(subscribed: false)) { XCTAssertEqual($0 as? ExportAllowance.Failure, .subscriptionRequired) }
        XCTAssertEqual(persisted, ExportUsageRecord(completed: 1, limit: 1))
        let restarted = ExportAllowance(read: { persisted }, write: { persisted = $0 })
        XCTAssertThrowsError(try restarted.begin(subscribed: false))
    }
    func testTrialCTARequiresEligibleActualThreeDayFreeTrial() {
        XCTAssertTrue(SubscriptionOfferPolicy.hasThreeDayTrial(eligible: true, freeTrial: true, days: 3))
        XCTAssertFalse(SubscriptionOfferPolicy.hasThreeDayTrial(eligible: false, freeTrial: true, days: 3))
        XCTAssertFalse(SubscriptionOfferPolicy.hasThreeDayTrial(eligible: true, freeTrial: false, days: 3))
        XCTAssertFalse(SubscriptionOfferPolicy.hasThreeDayTrial(eligible: true, freeTrial: true, days: 7))
        XCTAssertFalse(SubscriptionOfferPolicy.hasThreeDayTrial(eligible: true, freeTrial: true, days: nil))
    }
    func testSavingsUseActualPricesAndNeverAdvertiseNegativeSavings() {
        XCTAssertEqual(SubscriptionOfferPolicy.yearlySavings(monthly: Decimal(string: "12.99")!, yearly: Decimal(string: "99.99")!), 36)
        XCTAssertEqual(SubscriptionOfferPolicy.yearlySavings(monthly: 10, yearly: 60), 50)
        XCTAssertNil(SubscriptionOfferPolicy.yearlySavings(monthly: 10, yearly: 120))
        XCTAssertNil(SubscriptionOfferPolicy.yearlySavings(monthly: 0, yearly: 99))
        XCTAssertNil(SubscriptionOfferPolicy.yearlySavings(monthly: 10, yearly: -1))
    }
}
