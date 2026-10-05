import Foundation

struct SupabaseGallery: VeilCloudGallery {
    let auth: SupabaseAuthentication
    private func token(for user: UUID) async throws -> String {
        let session = try await auth.client.session
        guard session.user.id == user else { throw AccountFailure.invalidIdentity }
        return session.accessToken
    }
    func list(user: UUID) async throws -> [CloudGalleryItem] {
        var results: [CloudGalleryItem] = [], offset = 0
        while true {
            try Task.checkCancellation()
            let data = try await auth.transport.request(path: "rest/v1/gallery_items", method: "GET", token: token(for: user), query: [
                URLQueryItem(name: "select", value: "*"), URLQueryItem(name: "user_id", value: "eq.\(user.uuidString)"),
                URLQueryItem(name: "order", value: "id.asc"), URLQueryItem(name: "limit", value: "200"), URLQueryItem(name: "offset", value: "\(offset)")])
            let page = try Self.decoder.decode([CloudGalleryItem].self, from: data)
            for item in page { try item.validate(for: user) }
            results += page; if page.count < 200 { return results }; offset += page.count
        }
    }
    func upload(_ item: CloudGalleryItem, processed: Data, thumbnail: Data) async throws {
        try item.validate(for: item.userID)
        for (path, data) in [(item.processedPath, processed), (item.thumbnailPath, thumbnail)] {
            try Task.checkCancellation()
            _ = try await auth.transport.request(path: "storage/v1/object/veil-gallery/\(path)", method: "POST", token: token(for: item.userID),
                data: data, contentType: "image/jpeg", headers: ["x-upsert": "true", "Cache-Control": "no-store"])
        }
        try Task.checkCancellation()
        _ = try await auth.transport.request(path: "rest/v1/gallery_items", method: "POST", token: token(for: item.userID),
            data: Self.encoder.encode(item), headers: ["Prefer": "resolution=merge-duplicates"])
    }
    func download(_ item: CloudGalleryItem) async throws -> Data {
        try item.validate(for: item.userID)
        return try await auth.transport.request(path: "storage/v1/object/authenticated/veil-gallery/\(item.processedPath)",
                                                method: "GET", token: token(for: item.userID))
    }
    func delete(user: UUID, id: UUID) async throws {
        // Server marks a tombstone first and removes both objects. Retry repairs interrupted deletion.
        try await auth.transport.function("delete-gallery-item", token: token(for: user), body: ["id": id.uuidString])
    }
    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601; return encoder
    }
    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: text) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: text) else { throw AccountFailure.unavailable }; return date
        }
        return decoder
    }
}
