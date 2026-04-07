#!/usr/bin/swift

import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    fputs("Usage: generate-menu-bar-icon.swift <input-png> <output-png>\n", stderr)
    exit(1)
}

let inputURL = URL(fileURLWithPath: arguments[1])
let outputURL = URL(fileURLWithPath: arguments[2])

guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
      let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fputs("Unable to load source image at \(inputURL.path)\n", stderr)
    exit(1)
}

let width = cgImage.width
let height = cgImage.height
let bytesPerPixel = 4
let bytesPerRow = width * bytesPerPixel
let colorSpace = CGColorSpaceCreateDeviceRGB()
var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

guard let context = CGContext(
    data: &pixels,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: bytesPerRow,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("Unable to create bitmap context\n", stderr)
    exit(1)
}

context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

let background = averageCornerColor(width: width, height: height, pixels: pixels)
let threshold: Double = 42
let dilationRadius = 2

var minX = width
var minY = height
var maxX = 0
var maxY = 0
var foundForeground = false
var mask = [UInt8](repeating: 0, count: width * height)

for y in 0..<height {
    for x in 0..<width {
        let index = (y * width + x) * bytesPerPixel
        let r = Double(pixels[index])
        let g = Double(pixels[index + 1])
        let b = Double(pixels[index + 2])
        let distance = colorDistance(r, g, b, background.r, background.g, background.b)
        let isForeground = distance > threshold && (r + g + b) / 3 < 245

        if isForeground {
            mask[y * width + x] = UInt8(clamping: Int(max(172, min(255, distance * 3.8))))
            foundForeground = true
        }
    }
}

guard foundForeground else {
    fputs("No foreground detected in \(inputURL.path)\n", stderr)
    exit(1)
}

let thickenedMask = dilate(mask: mask, width: width, height: height, radius: dilationRadius)

for y in 0..<height {
    for x in 0..<width {
        let index = (y * width + x) * bytesPerPixel
        let alpha = thickenedMask[y * width + x]

        pixels[index] = 0
        pixels[index + 1] = 0
        pixels[index + 2] = 0
        pixels[index + 3] = alpha

        if alpha > 0 {
            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
        }
    }
}

let cropPadding = 10
minX = max(minX - cropPadding, 0)
minY = max(minY - cropPadding, 0)
maxX = min(maxX + cropPadding, width - 1)
maxY = min(maxY + cropPadding, height - 1)

let cropWidth = maxX - minX + 1
let cropHeight = maxY - minY + 1
let side = max(cropWidth, cropHeight) + 22
let outputSide = max(side, 64)
let outputBytesPerRow = outputSide * bytesPerPixel
var outputPixels = [UInt8](repeating: 0, count: outputSide * outputSide * bytesPerPixel)

let xOffset = (outputSide - cropWidth) / 2
let yOffset = (outputSide - cropHeight) / 2

for y in 0..<cropHeight {
    let sourceRow = minY + y
    let destinationRow = yOffset + y
    for x in 0..<cropWidth {
        let sourceColumn = minX + x
        let destinationColumn = xOffset + x
        let sourceIndex = (sourceRow * width + sourceColumn) * bytesPerPixel
        let destinationIndex = (destinationRow * outputSide + destinationColumn) * bytesPerPixel
        outputPixels[destinationIndex] = pixels[sourceIndex]
        outputPixels[destinationIndex + 1] = pixels[sourceIndex + 1]
        outputPixels[destinationIndex + 2] = pixels[sourceIndex + 2]
        outputPixels[destinationIndex + 3] = pixels[sourceIndex + 3]
    }
}

guard let outputContext = CGContext(
    data: &outputPixels,
    width: outputSide,
    height: outputSide,
    bitsPerComponent: 8,
    bytesPerRow: outputBytesPerRow,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
), let outputImage = outputContext.makeImage() else {
    fputs("Unable to create output image\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fputs("Unable to create destination at \(outputURL.path)\n", stderr)
    exit(1)
}

CGImageDestinationAddImage(destination, outputImage, nil)
guard CGImageDestinationFinalize(destination) else {
    fputs("Unable to finalize PNG at \(outputURL.path)\n", stderr)
    exit(1)
}

func averageCornerColor(width: Int, height: Int, pixels: [UInt8]) -> (r: Double, g: Double, b: Double) {
    let sampleSize = min(18, min(width, height) / 4)
    var totals = (r: 0.0, g: 0.0, b: 0.0, count: 0.0)
    let corners = [
        (0, 0),
        (width - sampleSize, 0),
        (0, height - sampleSize),
        (width - sampleSize, height - sampleSize),
    ]

    for (originX, originY) in corners {
        for y in originY..<(originY + sampleSize) {
            for x in originX..<(originX + sampleSize) {
                let index = (y * width + x) * 4
                totals.r += Double(pixels[index])
                totals.g += Double(pixels[index + 1])
                totals.b += Double(pixels[index + 2])
                totals.count += 1
            }
        }
    }

    return (
        totals.r / totals.count,
        totals.g / totals.count,
        totals.b / totals.count
    )
}

func colorDistance(_ r1: Double, _ g1: Double, _ b1: Double, _ r2: Double, _ g2: Double, _ b2: Double) -> Double {
    let dr = r1 - r2
    let dg = g1 - g2
    let db = b1 - b2
    return sqrt(dr * dr + dg * dg + db * db)
}

func dilate(mask: [UInt8], width: Int, height: Int, radius: Int) -> [UInt8] {
    var output = mask

    for y in 0..<height {
        for x in 0..<width {
            var strongest: UInt8 = 0
            for offsetY in -radius...radius {
                for offsetX in -radius...radius {
                    let sampleX = x + offsetX
                    let sampleY = y + offsetY
                    guard sampleX >= 0, sampleX < width, sampleY >= 0, sampleY < height else {
                        continue
                    }
                    strongest = max(strongest, mask[sampleY * width + sampleX])
                }
            }
            output[y * width + x] = strongest
        }
    }

    return output
}
