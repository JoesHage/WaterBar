#!/usr/bin/swift

import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 4,
      let width = Double(arguments[2]),
      let height = Double(arguments[3]) else {
    fputs("Usage: generate-dmg-background.swift <output-path> <width> <height>\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: arguments[1])

let canvasSize = NSSize(width: width, height: height)
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvasSize.width),
    pixelsHigh: Int(canvasSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Unable to allocate bitmap context\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("Unable to create graphics context\n", stderr)
    exit(1)
}

NSGraphicsContext.current = context
drawBackground(in: NSRect(origin: .zero, size: canvasSize))
context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode PNG output\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try pngData.write(to: outputURL)

func drawBackground(in rect: NSRect) {
    drawGradient(in: rect)
    drawTitle(in: rect)
    drawArrow(in: rect)
}

func drawGradient(in rect: NSRect) {
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.97, green: 0.95, blue: 0.91, alpha: 1),
        NSColor(calibratedRed: 0.94, green: 0.92, blue: 0.88, alpha: 1),
    ])!
    gradient.draw(in: rect, angle: -90)
}

func drawTitle(in rect: NSRect) {
    let fontSize = rect.width / 21.3
    let title = NSAttributedString(
        string: "Drag WaterBar to Applications",
        attributes: centeredAttributes(size: fontSize, weight: .bold, color: NSColor(calibratedWhite: 0.16, alpha: 1))
    )
    let titleHeight = fontSize * 1.35
    let titleRect = NSRect(
        x: rect.width * 0.11,
        y: rect.height * 0.79,
        width: rect.width * 0.78,
        height: titleHeight
    )
    title.draw(in: titleRect)
}

func drawArrow(in rect: NSRect) {
    let color = NSColor(calibratedWhite: 0.22, alpha: 0.62)

    let shaft = NSBezierPath()
    shaft.lineWidth = rect.width * 0.0085
    shaft.lineCapStyle = .round
    shaft.lineJoinStyle = .round
    shaft.move(to: NSPoint(x: rect.width * 0.445, y: rect.height * 0.41))
    shaft.curve(
        to: NSPoint(x: rect.width * 0.585, y: rect.height * 0.41),
        controlPoint1: NSPoint(x: rect.width * 0.49, y: rect.height * 0.41),
        controlPoint2: NSPoint(x: rect.width * 0.545, y: rect.height * 0.41)
    )
    color.setStroke()
    shaft.stroke()

    let head = NSBezierPath()
    head.lineWidth = rect.width * 0.0085
    head.lineCapStyle = .round
    head.lineJoinStyle = .round
    head.move(to: NSPoint(x: rect.width * 0.585, y: rect.height * 0.41))
    head.line(to: NSPoint(x: rect.width * 0.565, y: rect.height * 0.43))
    head.move(to: NSPoint(x: rect.width * 0.585, y: rect.height * 0.41))
    head.line(to: NSPoint(x: rect.width * 0.565, y: rect.height * 0.39))
    color.setStroke()
    head.stroke()
}

func centeredAttributes(size: CGFloat, weight: NSFont.Weight, color: NSColor) -> [NSAttributedString.Key: Any] {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    return [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: paragraph,
    ]
}
