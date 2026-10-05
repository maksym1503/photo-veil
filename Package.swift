// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PhotoVeilGeometry",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "ImageGeometry", path: "Sources/PhotoVeil", exclude: ["BlurRenderer.swift", "PhotoVeilApp.swift", "PhotoVeilHome.swift", "VeilPresentation.swift", "ZoomablePhotoCanvas.swift"], sources: ["ImageGeometryMapper.swift", "PrivacyImageRenderer.swift", "FaceDetection.swift"]),
        .testTarget(name: "ImageGeometryTests", dependencies: ["ImageGeometry"], path: "Tests/PhotoVeilTests")
    ]
)
