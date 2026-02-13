# ScreenCaptureKit — Quick Reference

## Permission Request

```swift
actor ScreenMonitor {
    private(set) var hasPermission: Bool = false

    func requestPermission() async -> Bool {
        do {
            // This triggers the system permission dialog
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            hasPermission = true
            return true
        } catch {
            hasPermission = false
            return false
        }
    }
}
```

## Single Display Capture

```swift
func captureScreenshot() async throws -> Data {
    let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    guard let display = content.displays.first else {
        throw ScreenCaptureError.noDisplayFound
    }

    let filter = SCContentFilter(display: display, excludingWindows: [])
    let config = SCStreamConfiguration()
    config.width = min(display.width, 1568)   // Max for Claude Vision API
    config.height = min(display.height, 1568)
    config.showsCursor = false
    config.captureResolution = .best

    let image = try await SCScreenshotManager.captureImage(
        contentFilter: filter,
        configuration: config
    )

    return try jpegData(from: image)
}
```

## Multi-Display Capture (Side-by-Side Montage)

```swift
func captureScreenshot() async throws -> Data {
    let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    guard !content.displays.isEmpty else { throw ScreenCaptureError.noDisplayFound }

    // Divide resolution budget among displays
    let perDisplayMaxEdge = 1568 / max(content.displays.count, 1)

    var capturedImages: [(CGImage, Int, Int)] = []

    for display in content.displays {
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        let (w, h) = scaledSize(width: display.width, height: display.height, maxEdge: perDisplayMaxEdge)
        config.width = w
        config.height = h
        config.showsCursor = false
        config.captureResolution = .best

        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        capturedImages.append((image, w, h))
    }

    // Single display — return directly
    if capturedImages.count == 1 {
        return try jpegData(from: capturedImages[0].0)
    }

    // Multi-display — stitch side-by-side
    let montage = try createSideBySideMontage(images: capturedImages)
    return try jpegData(from: montage)
}
```

## Side-by-Side Montage

```swift
private func createSideBySideMontage(images: [(CGImage, Int, Int)]) throws -> CGImage {
    let totalWidth = images.reduce(0) { $0 + $1.1 }
    let maxHeight = images.map { $0.2 }.max() ?? 0

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: totalWidth,
        height: maxHeight,
        bitsPerComponent: 8,
        bytesPerRow: totalWidth * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { throw ScreenCaptureError.captureFailed }

    // Black background
    context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: totalWidth, height: maxHeight))

    // Draw side-by-side
    var xOffset = 0
    for (image, width, height) in images {
        let yOffset = (maxHeight - height) / 2
        context.draw(image, in: CGRect(x: xOffset, y: yOffset, width: width, height: height))
        xOffset += width
    }

    guard let result = context.makeImage() else { throw ScreenCaptureError.captureFailed }
    return result
}
```

## Scaling to API Limits

```swift
/// Claude Vision API limit: 1568px on longest edge
private let maxLongEdge: Int = 1568

private func scaledSize(width: Int, height: Int, maxEdge: Int) -> (Int, Int) {
    let longestEdge = max(width, height)
    guard longestEdge > maxEdge else { return (width, height) }
    let scale = Double(maxEdge) / Double(longestEdge)
    return (Int(Double(width) * scale), Int(Double(height) * scale))
}
```

## CGImage → JPEG Data

```swift
private let jpegQuality: CGFloat = 0.85

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
```

## Error Types

```swift
enum ScreenCaptureError: Error, Sendable {
    case permissionDenied
    case noDisplayFound
    case captureFailed
    case resizeFailed
    case jpegConversionFailed
}
```

## Key Rules

- **NEVER write screenshots to disk** — memory only (Data/CGImage)
- Use `actor` for ScreenMonitor (thread-safe)
- `NSBitmapImageRep` for JPEG conversion (macOS, NOT UIImage)
- `SCScreenshotManager.captureImage` for single-frame capture
- `config.showsCursor = false` — hide cursor in screenshots
- Max 1568px longest edge for Claude Vision API
- JPEG quality 0.85 for good balance of quality/size
