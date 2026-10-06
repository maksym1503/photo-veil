// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PhotoVeilGeometry",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "ImageGeometry", path: "Sources/PhotoVeil", exclude: ["Resources", "BlurRenderer.swift", "PhotoVeilApp.swift", "PhotoVeilHome.swift", "VeilPresentation.swift", "ZoomablePhotoCanvas.swift", "VeilLibrary.swift", "VeilGallery.swift", "PhotosSaver.swift", "BackendTransport.swift", "SupabaseAuthentication.swift", "ProtectedAuthStorage.swift", "SupabaseGallery.swift", "VeilAccount.swift", "OAuthPresentation.swift"], sources: ["ImageGeometryMapper.swift", "PrivacyImageRenderer.swift", "FaceDetection.swift", "DetectedPrivacySelection.swift", "DocumentDetection.swift", "GalleryStore.swift", "PhotoSavePolicy.swift", "AccountContracts.swift", "CloudSync.swift", "BackendConfiguration.swift"]),
        .testTarget(name: "ImageGeometryTests", dependencies: ["ImageGeometry"], path: "Tests/PhotoVeilTests")
    ]
)
