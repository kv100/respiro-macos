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

    /// Capture the main display and return JPEG `Data` (never written to disk).
    func captureScreenshot() async throws -> Data {
        // 1. Obtain shareable content (also checks permission)
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        } catch {
            hasPermission = false
            throw ScreenCaptureError.permissionDenied
        }

        guard let display = content.displays.first else {
            throw ScreenCaptureError.noDisplayFound
        }
        hasPermission = true

        // 2. Configure capture — scale down to API-friendly size
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()

        let (captureWidth, captureHeight) = scaledSize(
            width: display.width,
            height: display.height,
            maxEdge: maxLongEdge
        )
        config.width = captureWidth
        config.height = captureHeight
        config.showsCursor = false
        config.captureResolution = .best

        // 3. Capture
        let image: CGImage
        do {
            image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
        } catch {
            throw ScreenCaptureError.captureFailed
        }

        // 4. Convert CGImage → JPEG Data
        let jpegData = try jpegData(from: image)
        return jpegData
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
