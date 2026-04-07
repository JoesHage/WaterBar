import AppKit

public enum WaterBarIcon {
    public static func menuBarImage() -> NSImage {
        if let bundled = bundledMenuBarImage() {
            return bundled
        }

        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        drawMenuBarCup(in: NSRect(origin: .zero, size: size))
        image.isTemplate = true
        return image
    }

    private static func bundledMenuBarImage() -> NSImage? {
        if let pngURL = Bundle.module.url(forResource: "menuBarIcon", withExtension: "png"),
           let pngImage = NSImage(contentsOf: pngURL) {
            pngImage.size = NSSize(width: 18, height: 18)
            pngImage.isTemplate = true
            return pngImage
        }

        guard let pdfURL = Bundle.module.url(forResource: "menuBarIcon", withExtension: "pdf"),
              let pdfImage = NSImage(contentsOf: pdfURL) else {
            return nil
        }

        // Ignore full-page PDF exports; they render the actual mark too small to be visible in the menu bar.
        guard pdfImage.size.width <= 64, pdfImage.size.height <= 64 else {
            return nil
        }

        pdfImage.size = NSSize(width: 18, height: 18)
        pdfImage.isTemplate = true
        return pdfImage
    }

    private static func drawMenuBarCup(in rect: NSRect) {
        let drawingRect = rect.insetBy(dx: 1.9, dy: 1.35)
        let strokeColor = NSColor.labelColor
        let lineWidth = 2.0
        let topY = drawingRect.maxY - drawingRect.height * 0.11
        let bottomY = drawingRect.minY + drawingRect.height * 0.06
        let leftTop = NSPoint(x: drawingRect.minX + drawingRect.width * 0.08, y: topY)
        let rightTop = NSPoint(x: drawingRect.maxX - drawingRect.width * 0.08, y: topY)
        let leftBottom = NSPoint(x: drawingRect.minX + drawingRect.width * 0.24, y: bottomY)
        let rightBottom = NSPoint(x: drawingRect.maxX - drawingRect.width * 0.24, y: bottomY)

        let cupPath = NSBezierPath()
        cupPath.lineWidth = lineWidth
        cupPath.lineCapStyle = .round
        cupPath.lineJoinStyle = .round
        cupPath.move(to: leftTop)
        cupPath.line(to: rightTop)
        cupPath.curve(
            to: rightBottom,
            controlPoint1: NSPoint(x: drawingRect.maxX - drawingRect.width * 0.05, y: drawingRect.maxY - drawingRect.height * 0.44),
            controlPoint2: NSPoint(x: drawingRect.maxX - drawingRect.width * 0.08, y: drawingRect.minY + drawingRect.height * 0.19)
        )
        cupPath.curve(
            to: leftBottom,
            controlPoint1: NSPoint(x: drawingRect.maxX - drawingRect.width * 0.40, y: drawingRect.minY - drawingRect.height * 0.01),
            controlPoint2: NSPoint(x: drawingRect.minX + drawingRect.width * 0.40, y: drawingRect.minY - drawingRect.height * 0.01)
        )
        cupPath.curve(
            to: leftTop,
            controlPoint1: NSPoint(x: drawingRect.minX + drawingRect.width * 0.08, y: drawingRect.minY + drawingRect.height * 0.19),
            controlPoint2: NSPoint(x: drawingRect.minX + drawingRect.width * 0.05, y: drawingRect.maxY - drawingRect.height * 0.44)
        )
        strokeColor.setStroke()
        cupPath.stroke()

        let wavePath = NSBezierPath()
        wavePath.lineWidth = 1.8
        wavePath.lineCapStyle = .round
        wavePath.move(to: NSPoint(x: drawingRect.minX + drawingRect.width * 0.14, y: drawingRect.maxY - drawingRect.height * 0.34))
        wavePath.curve(
            to: NSPoint(x: drawingRect.maxX - drawingRect.width * 0.14, y: drawingRect.maxY - drawingRect.height * 0.36),
            controlPoint1: NSPoint(x: drawingRect.minX + drawingRect.width * 0.33, y: drawingRect.maxY - drawingRect.height * 0.25),
            controlPoint2: NSPoint(x: drawingRect.maxX - drawingRect.width * 0.33, y: drawingRect.maxY - drawingRect.height * 0.41)
        )
        strokeColor.setStroke()
        wavePath.stroke()
    }
}
