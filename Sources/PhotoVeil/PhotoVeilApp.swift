import SwiftUI

@main
struct PhotoVeilApp: App {
    @StateObject private var library = VeilLibrary()
    init() { TemporaryPhoto.clearPreviousSession() }
    var body: some Scene {
        WindowGroup { PhotoVeilHome().environmentObject(library) }
    }
}
