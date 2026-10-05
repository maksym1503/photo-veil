import Foundation

enum PhotoSavePermission: Sendable { case notDetermined, authorized, limited, denied, restricted, unknown }
enum PhotoSaveError: Error { case denied, restricted, unavailable }
protocol PhotoSaveAccess: Sendable {
    func status() async -> PhotoSavePermission
    func requestAddOnly() async -> PhotoSavePermission
    func write(_ data: Data) async throws
}
enum PhotoSavePolicy {
    static func save(_ data: Data, using access: any PhotoSaveAccess) async throws {
        var status = await access.status()
        if status == .notDetermined { status = await access.requestAddOnly() }
        switch status {
        case .authorized, .limited: try await access.write(data)
        case .denied: throw PhotoSaveError.denied
        case .restricted: throw PhotoSaveError.restricted
        case .unknown, .notDetermined: throw PhotoSaveError.unavailable
        }
    }
}
