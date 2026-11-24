// swift-tools-version: 5.9
// This Package.swift is for reference / SPM-only builds.
// For the full Xcode project build, open ChessOverlay.xcodeproj.
import PackageDescription

let package = Package(
    name: "ChessOverlay",
    platforms: [.iOS(.v16)],
    targets: [
        .executableTarget(
            name: "ChessOverlay",
            path: "ChessOverlay",
            resources: [
                .process("Info.plist"),
                // After compiling Stockfish for arm64-apple-ios, drop the binary here:
                // .copy("Engine/stockfish")
                // If you have a trained PieceClassifier model, add it here:
                // .process("Vision/PieceClassifier.mlmodelc")
            ]
        )
    ]
)
