import AppKit
import Foundation

let size = 1024
let outputURL = URL(fileURLWithPath: "Resources/AppIcon-1024.png")

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Failed to create bitmap\n", stderr)
    exit(1)
}
rep.size = NSSize(width: size, height: size)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
defer { NSGraphicsContext.restoreGraphicsState() }

let f = CGFloat(size)
let rect = NSRect(x: 0, y: 0, width: f, height: f)

// Rounded background: dark navy -> violet gradient
let bg = NSBezierPath(roundedRect: rect, xRadius: f * 0.22, yRadius: f * 0.22)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.22, alpha: 1),
    NSColor(calibratedRed: 0.28, green: 0.12, blue: 0.62, alpha: 1),
])!
gradient.draw(in: bg, angle: -90)

// Faint glow circle behind bubble
NSColor(calibratedRed: 0.6, green: 0.4, blue: 1.0, alpha: 0.18).setFill()
NSBezierPath(ovalIn: NSRect(x: f * 0.10, y: f * 0.14, width: f * 0.80, height: f * 0.80)).fill()

// Speech bubble + tail
let bubbleRect = NSRect(x: f * 0.17, y: f * 0.22, width: f * 0.66, height: f * 0.58)
let bubble = NSBezierPath(roundedRect: bubbleRect, xRadius: f * 0.15, yRadius: f * 0.15)
let tail = NSBezierPath()
tail.move(to: NSPoint(x: f * 0.30, y: bubbleRect.minY))
tail.line(to: NSPoint(x: f * 0.20, y: bubbleRect.minY - f * 0.13))
tail.line(to: NSPoint(x: f * 0.44, y: bubbleRect.minY))
tail.close()
bubble.append(tail)
NSColor(calibratedWhite: 1, alpha: 0.97).setFill()
bubble.fill()

// Three platform dots
let dots: [NSColor] = [
    NSColor(calibratedRed: 0.15, green: 0.55, blue: 1.0, alpha: 1),
    NSColor(calibratedRed: 0.95, green: 0.25, blue: 0.25, alpha: 1),
    NSColor(calibratedRed: 0.92, green: 0.30, blue: 0.75, alpha: 1),
]
let dotRadius = f * 0.06
let dotCY: CGFloat = f * 0.60
for (i, color) in dots.enumerated() {
    let cx = f * 0.27 + CGFloat(i) * f * 0.235
    color.setFill()
    NSBezierPath(ovalIn: NSRect(
        x: cx - dotRadius, y: dotCY - dotRadius,
        width: dotRadius * 2, height: dotRadius * 2
    )).fill()
}

// Green checkmark
let check = NSBezierPath()
check.move(to: NSPoint(x: f * 0.33, y: f * 0.36))
check.line(to: NSPoint(x: f * 0.465, y: f * 0.20))
check.line(to: NSPoint(x: f * 0.72, y: f * 0.51))
check.lineWidth = f * 0.065
check.lineCapStyle = .round
check.lineJoinStyle = .round
NSColor(calibratedRed: 0.10, green: 0.72, blue: 0.35, alpha: 1).setStroke()
check.stroke()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fputs("Failed to encode PNG\n", stderr)
    exit(1)
}

do {
    try png.write(to: outputURL)
    print("Wrote \(outputURL.path)")
} catch {
    fputs("Failed to write icon: \(error)\n", stderr)
    exit(1)
}
