import ScreenCaptureKit
import AppKit
import CoreGraphics

// MARK: - Errors

enum ScreenCaptureError: Error, Sendable {
    case permissionDenied
    case noDisplayFound
    case captureFailed
    case resizeFailed
    case jpegConversionFailed
}

// MARK: - ScreenMonitor

actor ScreenMonitor {

    /// Maximum pixel dimension on the longest edge (API limit).
    private let maxLongEdge: Int = 1568

    /// JPEG compression quality (0.0–1.0).
    private let jpegQuality: CGFloat = 0.85

    // MARK: - Permission

    private(set) var hasPermission: Bool = false

    /// Attempt to trigger / verify Screen Recording permission.
    /// Returns `true` if the user has already granted access.
    func requestPermission() async -> Bool {
        do {
            // Requesting shareable content is the canonical way to trigger
            // the system permission prompt and verify access.
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            hasPermission = true
            return true
        } catch {
            hasPermission = false
            return false
        }
    }

    // MARK: - Capture

    /// Capture all displays and return JPEG `Data` (never written to disk).
    /// For multi-monitor setups, images are stitched side-by-side.
    func captureScreenshot() async throws -> Data {
        // 1. Obtain shareable content (also checks permission)
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        } catch {
            hasPermission = false
            throw ScreenCaptureError.permissionDenied
        }

        guard !content.displays.isEmpty else {
            throw ScreenCaptureError.noDisplayFound
        }
        hasPermission = true

        // 2. Capture each display as CGImage
        var capturedImages: [(CGImage, Int, Int)] = []

        // Divide max resolution budget among displays
        let perDisplayMaxEdge = maxLongEdge / max(content.displays.count, 1)

        for display in content.displays {
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()

            // Scale down each display to fit API limits
            let (captureWidth, captureHeight) = scaledSize(
                width: display.width,
                height: display.height,
                maxEdge: perDisplayMaxEdge
            )
            config.width = captureWidth
            config.height = captureHeight
            config.showsCursor = false
            config.captureResolution = .best
            config.capturesAudio = false

            let image: CGImage
            do {
                image = try await SCScreenshotManager.captureImage(
                    contentFilter: filter,
                    configuration: config
                )
            } catch {
                throw ScreenCaptureError.captureFailed
            }

            capturedImages.append((image, captureWidth, captureHeight))
        }

        // 3. If single display, return as is
        if capturedImages.count == 1 {
            return try jpegData(from: capturedImages[0].0)
        }

        // 4. Montage side-by-side
        let montage = try createSideBySideMontage(images: capturedImages)

        // 5. Convert to JPEG
        return try jpegData(from: montage)
    }

    // MARK: - Private Helpers

    /// Calculate proportional size so the longest edge is at most `maxEdge`.
    private func scaledSize(width: Int, height: Int, maxEdge: Int) -> (Int, Int) {
        let longestEdge = max(width, height)
        guard longestEdge > maxEdge else {
            return (width, height)
        }
        let scale = Double(maxEdge) / Double(longestEdge)
        let newWidth = Int(Double(width) * scale)
        let newHeight = Int(Double(height) * scale)
        return (newWidth, newHeight)
    }

    /// Stitch multiple CGImages horizontally (side-by-side).
    private func createSideBySideMontage(images: [(CGImage, Int, Int)]) throws -> CGImage {
        // Calculate total width and max height
        let totalWidth = images.reduce(0) { $0 + $1.1 }
        let maxHeight = images.map { $0.2 }.max() ?? 0

        guard totalWidth > 0, maxHeight > 0 else {
            throw ScreenCaptureError.captureFailed
        }

        // Create bitmap context
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: totalWidth,
            height: maxHeight,
            bitsPerComponent: 8,
            bytesPerRow: totalWidth * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw ScreenCaptureError.captureFailed
        }

        // Fill with black background
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: totalWidth, height: maxHeight))

        // Draw each image side-by-side
        var xOffset = 0
        for (image, width, height) in images {
            // Center vertically if heights differ
            let yOffset = (maxHeight - height) / 2
            context.draw(image, in: CGRect(x: xOffset, y: yOffset, width: width, height: height))
            xOffset += width
        }

        // Create final CGImage
        guard let finalImage = context.makeImage() else {
            throw ScreenCaptureError.captureFailed
        }

        return finalImage
    }

    /// Convert a `CGImage` to JPEG `Data` using `NSBitmapImageRep`.
    private func jpegData(from cgImage: CGImage) throws -> Data {
        let rep = NSBitmapImageRep(cgImage: cgImage)
        guard let data = rep.representation(
            using: .jpeg,
            properties: [.compressionFactor: jpegQuality]
        ) else {
            throw ScreenCaptureError.jpegConversionFailed
        }
        return data
    }
}
