#!/usr/bin/swift

import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    fputs("Usage: render-installer-mockup.swift <output-png>\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: arguments[1])
let fileManager = FileManager.default
let waterBarIconURL = URL(fileURLWithPath: "/Users/joehage/Documents/WaterBar/Support/water.png")

guard let waterBarIcon = NSImage(contentsOf: waterBarIconURL) else {
    fputs("Unable to load WaterBar icon\n", stderr)
    exit(1)
}

let canvasSize = NSSize(width: 1152, height: 768)
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
    fputs("Unable to allocate bitmap\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("Unable to create graphics context\n", stderr)
    exit(1)
}
NSGraphicsContext.current = context

drawMockup(in: NSRect(origin: .zero, size: canvasSize), waterBarIcon: waterBarIcon)

context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode output PNG\n", stderr)
    exit(1)
}

try fileManager.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try pngData.write(to: outputURL)

func drawMockup(in rect: NSRect, waterBarIcon: NSImage) {
    NSColor.black.setFill()
    rect.fill()

    let windowRect = NSRect(x: 84, y: 76, width: 959, height: 613)
    let windowShadow = NSShadow()
    windowShadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
    windowShadow.shadowBlurRadius = 28
    windowShadow.shadowOffset = NSSize(width: 0, height: -8)
    windowShadow.set()

    let windowPath = NSBezierPath(roundedRect: windowRect, xRadius: 24, yRadius: 24)
    NSColor.white.setFill()
    windowPath.fill()

    NSGraphicsContext.current?.saveGraphicsState()
    let clipPath = NSBezierPath(roundedRect: windowRect, xRadius: 24, yRadius: 24)
    clipPath.addClip()

    let contentRect = windowRect.insetBy(dx: 0, dy: 0)
    let titleBarRect = NSRect(x: contentRect.minX, y: contentRect.maxY - 58, width: contentRect.width, height: 58)
    NSColor(calibratedWhite: 0.97, alpha: 1).setFill()
    titleBarRect.fill()

    let bodyRect = NSRect(x: contentRect.minX, y: contentRect.minY, width: contentRect.width, height: contentRect.height - 58)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.972, green: 0.957, blue: 0.927, alpha: 1),
        NSColor(calibratedRed: 0.958, green: 0.944, blue: 0.915, alpha: 1),
    ])!
    gradient.draw(in: bodyRect, angle: -90)

    let glow = NSColor.white.withAlphaComponent(0.28)
    glow.setFill()
    NSBezierPath(ovalIn: NSRect(x: 175, y: 420, width: 180, height: 120)).fill()
    NSBezierPath(ovalIn: NSRect(x: 665, y: 398, width: 210, height: 138)).fill()

    drawTrafficLights(in: titleBarRect)
    drawWindowTitle(in: titleBarRect)
    drawBodyContent(in: bodyRect, waterBarIcon: waterBarIcon)

    NSGraphicsContext.current?.restoreGraphicsState()
}

func drawTrafficLights(in rect: NSRect) {
    let colors: [NSColor] = [
        NSColor(calibratedRed: 0.95, green: 0.38, blue: 0.35, alpha: 1),
        NSColor(calibratedRed: 0.98, green: 0.77, blue: 0.23, alpha: 1),
        NSColor(calibratedRed: 0.38, green: 0.78, blue: 0.35, alpha: 1),
    ]

    for (index, color) in colors.enumerated() {
        let circle = NSBezierPath(ovalIn: NSRect(x: rect.minX + 16 + CGFloat(index) * 32, y: rect.midY - 11, width: 22, height: 22))
        color.setFill()
        circle.fill()
    }
}

func drawWindowTitle(in rect: NSRect) {
    let iconRect = NSRect(x: rect.minX + 127, y: rect.midY - 8, width: 16, height: 18)
    NSColor(calibratedWhite: 0.9, alpha: 1).setFill()
    NSBezierPath(roundedRect: iconRect, xRadius: 3, yRadius: 3).fill()

    let lockBody = NSBezierPath(roundedRect: NSRect(x: iconRect.minX + 3, y: iconRect.minY + 2, width: 10, height: 8), xRadius: 2, yRadius: 2)
    NSColor(calibratedWhite: 0.8, alpha: 1).setFill()
    lockBody.fill()

    let title = NSAttributedString(
        string: "WaterBar",
        attributes: [
            .font: NSFont.systemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: NSColor(calibratedWhite: 0.28, alpha: 0.92),
        ]
    )
    title.draw(at: NSPoint(x: rect.minX + 155, y: rect.midY - 14))
}

func drawBodyContent(in rect: NSRect, waterBarIcon: NSImage) {
    let title = NSAttributedString(
        string: "Drag WaterBar to",
        attributes: centeredAttributes(size: 52, weight: .semibold, color: NSColor(calibratedWhite: 0.18, alpha: 1))
    )
    title.draw(in: NSRect(x: rect.minX + 210, y: rect.maxY - 148, width: 540, height: 64))

    let subtitle = NSAttributedString(
        string: "Install once, then launch it from your Applications folder.",
        attributes: centeredAttributes(size: 22, weight: .medium, color: NSColor(calibratedWhite: 0.38, alpha: 0.95))
    )
    subtitle.draw(in: NSRect(x: rect.minX + 160, y: rect.maxY - 205, width: 640, height: 30))

    let leftIconRect = NSRect(x: rect.minX + 154, y: rect.minY + 148, width: 126, height: 126)
    drawIconPlate(in: leftIconRect, icon: waterBarIcon)

    let applicationsRect = NSRect(x: rect.minX + 690, y: rect.minY + 140, width: 148, height: 148)
    drawApplicationsFolderIcon(in: applicationsRect)

    let waterBarLabel = NSAttributedString(
        string: "WaterBar",
        attributes: centeredAttributes(size: 24, weight: .medium, color: NSColor(calibratedWhite: 0.18, alpha: 1))
    )
    waterBarLabel.draw(in: NSRect(x: leftIconRect.minX - 30, y: leftIconRect.minY - 64, width: 186, height: 30))

    let applicationsLabel = NSAttributedString(
        string: "Applications",
        attributes: centeredAttributes(size: 24, weight: .medium, color: NSColor(calibratedWhite: 0.18, alpha: 1))
    )
    applicationsLabel.draw(in: NSRect(x: applicationsRect.minX - 24, y: applicationsRect.minY - 70, width: 196, height: 30))

    drawCurvedArrow(from: NSPoint(x: 392, y: 304), to: NSPoint(x: 691, y: 286))
}

func drawIconPlate(in rect: NSRect, icon: NSImage) {
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.10)
    shadow.shadowBlurRadius = 12
    shadow.shadowOffset = NSSize(width: 0, height: -3)
    shadow.set()

    let plate = NSBezierPath(roundedRect: rect, xRadius: 28, yRadius: 28)
    NSColor.white.withAlphaComponent(0.98).setFill()
    plate.fill()

    NSGraphicsContext.current?.saveGraphicsState()
    let clip = NSBezierPath(roundedRect: rect.insetBy(dx: 14, dy: 14), xRadius: 18, yRadius: 18)
    clip.addClip()
    icon.draw(in: rect.insetBy(dx: 14, dy: 14))
    NSGraphicsContext.current?.restoreGraphicsState()
}

func drawApplicationsFolderIcon(in rect: NSRect) {
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.12)
    shadow.shadowBlurRadius = 14
    shadow.shadowOffset = NSSize(width: 0, height: -4)
    shadow.set()

    let folderRect = rect.insetBy(dx: 10, dy: 8)
    let bodyRect = NSRect(x: folderRect.minX, y: folderRect.minY, width: folderRect.width, height: folderRect.height - 14)
    let tabRect = NSRect(x: folderRect.minX + 10, y: folderRect.maxY - 48, width: 54, height: 26)

    let tabPath = NSBezierPath(roundedRect: tabRect, xRadius: 10, yRadius: 10)
    let tabGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.40, green: 0.75, blue: 0.96, alpha: 1),
        NSColor(calibratedRed: 0.32, green: 0.67, blue: 0.91, alpha: 1),
    ])!
    tabGradient.draw(in: tabPath, angle: -90)

    let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: 18, yRadius: 18)
    let bodyGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.50, green: 0.82, blue: 0.98, alpha: 1),
        NSColor(calibratedRed: 0.29, green: 0.65, blue: 0.89, alpha: 1),
    ])!
    bodyGradient.draw(in: bodyPath, angle: -90)

    NSColor.white.withAlphaComponent(0.18).setStroke()
    bodyPath.lineWidth = 1.4
    bodyPath.stroke()

    let highlight = NSBezierPath(roundedRect: NSRect(x: bodyRect.minX + 6, y: bodyRect.maxY - 18, width: bodyRect.width - 12, height: 14), xRadius: 7, yRadius: 7)
    NSColor.white.withAlphaComponent(0.25).setFill()
    highlight.fill()

    drawApplicationsGlyph(in: bodyRect)
}

func drawApplicationsGlyph(in rect: NSRect) {
    NSColor.white.withAlphaComponent(0.86).setStroke()

    let left = NSBezierPath()
    left.lineWidth = 7
    left.lineCapStyle = .round
    left.move(to: NSPoint(x: rect.midX - 18, y: rect.minY + 28))
    left.line(to: NSPoint(x: rect.midX + 2, y: rect.maxY - 34))
    left.stroke()

    let right = NSBezierPath()
    right.lineWidth = 7
    right.lineCapStyle = .round
    right.move(to: NSPoint(x: rect.midX + 18, y: rect.minY + 28))
    right.line(to: NSPoint(x: rect.midX - 2, y: rect.maxY - 34))
    right.stroke()

    let bridge = NSBezierPath()
    bridge.lineWidth = 7
    bridge.lineCapStyle = .round
    bridge.move(to: NSPoint(x: rect.midX - 28, y: rect.minY + 46))
    bridge.line(to: NSPoint(x: rect.midX + 28, y: rect.minY + 46))
    bridge.stroke()
}

func drawCurvedArrow(from start: NSPoint, to end: NSPoint) {
    let color = NSColor(calibratedWhite: 0.12, alpha: 0.68)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.08)
    shadow.shadowBlurRadius = 2
    shadow.shadowOffset = NSSize(width: 0, height: -1)
    shadow.set()

    let shaft = NSBezierPath()
    shaft.lineWidth = 7
    shaft.lineCapStyle = .round
    shaft.lineJoinStyle = .round
    shaft.move(to: start)
    shaft.curve(
        to: end,
        controlPoint1: NSPoint(x: 468, y: 452),
        controlPoint2: NSPoint(x: 604, y: 386)
    )
    color.setStroke()
    shaft.stroke()

    let headLower = NSBezierPath()
    headLower.lineWidth = 7
    headLower.lineCapStyle = .round
    headLower.move(to: end)
    headLower.curve(
        to: NSPoint(x: end.x - 22, y: end.y - 28),
        controlPoint1: NSPoint(x: end.x - 4, y: end.y - 8),
        controlPoint2: NSPoint(x: end.x - 10, y: end.y - 18)
    )
    color.setStroke()
    headLower.stroke()

    let headUpper = NSBezierPath()
    headUpper.lineWidth = 7
    headUpper.lineCapStyle = .round
    headUpper.move(to: end)
    headUpper.curve(
        to: NSPoint(x: end.x - 36, y: end.y + 2),
        controlPoint1: NSPoint(x: end.x - 10, y: end.y + 1),
        controlPoint2: NSPoint(x: end.x - 20, y: end.y + 2)
    )
    color.setStroke()
    headUpper.stroke()
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
