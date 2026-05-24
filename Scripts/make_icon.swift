#!/usr/bin/env swift
// make_icon.swift — Generates GlowCast.icns
// Run: swift Scripts/make_icon.swift
// Requires macOS 12+ (AppKit, CoreGraphics)

import AppKit
import Foundation

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

let scriptDir: String = {
    // __FILE__ gives the script path; dirname gives Scripts/
    let src = CommandLine.arguments[0]
    let url = URL(fileURLWithPath: src).deletingLastPathComponent()
    return url.path
}()

let iconsetPath = scriptDir + "/GlowCast.iconset"
let outputPath  = scriptDir + "/AppIcon.icns"

// Standard iconset sizes: (logical, scale)
let sizes: [(Int, Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2),
]

// ---------------------------------------------------------------------------
// Drawing
// ---------------------------------------------------------------------------

/// Draw a single icon at the given pixel dimension and return NSImage.
func drawIcon(pixels: Int) -> NSImage {
    let size = CGFloat(pixels)
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    // -- Background: rounded rect with diagonal gradient --
    let cornerRadius = size * 0.22
    let bgRect = CGRect(x: 0, y: 0, width: size, height: size)
    let roundedPath = CGPath(roundedRect: bgRect,
                             cornerWidth: cornerRadius,
                             cornerHeight: cornerRadius,
                             transform: nil)
    ctx.addPath(roundedPath)
    ctx.clip()

    // Gradient: deep indigo #1A1033 (top-left) → cyan #06B6D4 (bottom-right)
    // In CoreGraphics, y=0 is bottom, so "top-left" is (0, size), "bottom-right" is (size, 0).
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let indigoColor = CGColor(colorSpace: colorSpace,
                              components: [0x1A/255.0, 0x10/255.0, 0x33/255.0, 1.0])!
    let cyanColor   = CGColor(colorSpace: colorSpace,
                              components: [0x06/255.0, 0xB6/255.0, 0xD4/255.0, 1.0])!
    let gradient = CGGradient(colorsSpace: colorSpace,
                              colors: [indigoColor, cyanColor] as CFArray,
                              locations: [0.0, 1.0])!

    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: 0, y: size),       // top-left
                           end:   CGPoint(x: size, y: 0),       // bottom-right
                           options: [])

    // Reset clip
    ctx.resetClip()
    ctx.addPath(roundedPath)
    ctx.clip()

    // -- Microphone glyph --
    // Try SF Symbol first; fall back to Bezier paths.
    let glyphSize = size * 0.55
    let glyphRect = CGRect(
        x: (size - glyphSize) / 2,
        y: (size - glyphSize) / 2,
        width: glyphSize,
        height: glyphSize
    )

    var drewSymbol = false

    if let sfImage = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: nil) {
        // Tint white
        let tinted = NSImage(size: NSSize(width: glyphSize, height: glyphSize))
        tinted.lockFocus()
        if let tintCtx = NSGraphicsContext.current?.cgContext {
            tintCtx.setBlendMode(.normal)
            NSColor.white.setFill()
            // Draw symbol as template
            let symRect = NSRect(x: 0, y: 0, width: glyphSize, height: glyphSize)
            sfImage.draw(in: symRect,
                         from: .zero,
                         operation: .sourceOver,
                         fraction: 1.0,
                         respectFlipped: true,
                         hints: [.interpolation: NSNumber(value: NSImageInterpolation.high.rawValue)])
            // Composite white over it
            tintCtx.setFillColor(CGColor.white)
            tintCtx.setBlendMode(.sourceAtop)
            tintCtx.fill(symRect)
        }
        tinted.unlockFocus()

        // Draw cyan glow shadow behind the mic
        ctx.saveGState()
        let glowColor = CGColor(colorSpace: colorSpace,
                                components: [0x06/255.0, 0xB6/255.0, 0xD4/255.0, 0.6])!
        ctx.setShadow(offset: .zero, blur: size * 0.06, color: glowColor)
        tinted.draw(in: glyphRect,
                    from: .zero,
                    operation: .sourceOver,
                    fraction: 1.0,
                    respectFlipped: false,
                    hints: nil)
        ctx.restoreGState()

        // Draw again without shadow for crisp layer on top
        tinted.draw(in: glyphRect,
                    from: .zero,
                    operation: .sourceOver,
                    fraction: 1.0,
                    respectFlipped: false,
                    hints: nil)

        drewSymbol = true
    }

    if !drewSymbol {
        // Fallback: draw a mic with Bezier paths
        drawMicFallback(ctx: ctx, rect: glyphRect, size: size)
    }

    image.unlockFocus()
    return image
}

/// Simple mic shape via Bezier: capsule body + neck + stand arc
func drawMicFallback(ctx: CGContext, rect: CGRect, size: CGFloat) {
    let cyanGlow = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(),
                           components: [0x06/255.0, 0xB6/255.0, 0xD4/255.0, 0.6])!
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: size * 0.06, color: cyanGlow)
    ctx.setFillColor(CGColor.white)

    let cx = rect.midX
    let bw = rect.width  * 0.32   // body width
    let bh = rect.height * 0.52   // body height
    let by = rect.maxY - bh       // body top-y (remember: y=0 is bottom)

    // Capsule body
    let bodyRect = CGRect(x: cx - bw/2, y: by, width: bw, height: bh)
    let bodyPath = CGPath(roundedRect: bodyRect,
                          cornerWidth: bw/2,
                          cornerHeight: bw/2,
                          transform: nil)
    ctx.addPath(bodyPath)
    ctx.fillPath()

    // Stand: U-shape arc below body
    let standW = rect.width * 0.55
    let standH = rect.height * 0.25
    let standY = rect.minY + rect.height * 0.18
    let arcPath = CGMutablePath()
    arcPath.move(to: CGPoint(x: cx - standW/2, y: standY + standH))
    arcPath.addArc(center: CGPoint(x: cx, y: standY + standH),
                   radius: standW/2,
                   startAngle: .pi,
                   endAngle: 0,
                   clockwise: true)
    let strokeWidth = max(2, size * 0.025)
    ctx.addPath(arcPath)
    ctx.setStrokeColor(CGColor.white)
    ctx.setLineWidth(strokeWidth)
    ctx.strokePath()

    // Stem (vertical line below arc)
    let stemH = rect.height * 0.08
    ctx.move(to: CGPoint(x: cx, y: standY))
    ctx.addLine(to: CGPoint(x: cx, y: standY + stemH * 0.5))
    ctx.setLineWidth(strokeWidth)
    ctx.strokePath()

    // Base horizontal bar
    let barW = standW * 0.5
    let barPath = CGMutablePath()
    barPath.move(to: CGPoint(x: cx - barW/2, y: standY))
    barPath.addLine(to: CGPoint(x: cx + barW/2, y: standY))
    ctx.addPath(barPath)
    ctx.strokePath()

    ctx.restoreGState()
}

// ---------------------------------------------------------------------------
// Write PNGs to iconset
// ---------------------------------------------------------------------------

func filename(logical: Int, scale: Int) -> String {
    if scale == 1 {
        return "icon_\(logical)x\(logical).png"
    } else {
        return "icon_\(logical)x\(logical)@2x.png"
    }
}

// Create iconset directory
let fm = FileManager.default
try? fm.removeItem(atPath: iconsetPath)
try fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for (logical, scale) in sizes {
    let pixels = logical * scale
    print("  Rendering \(pixels)x\(pixels)...")
    let img = drawIcon(pixels: pixels)

    guard let tiffData = img.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("ERROR: failed to produce PNG for \(pixels)x\(pixels)")
        exit(1)
    }

    let name = filename(logical: logical, scale: scale)
    let dest = iconsetPath + "/" + name
    try pngData.write(to: URL(fileURLWithPath: dest))
    print("  Wrote \(name)")
}

// ---------------------------------------------------------------------------
// Convert to .icns
// ---------------------------------------------------------------------------

print("Converting iconset to \(outputPath) ...")
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetPath, "-o", outputPath]
try task.run()
task.waitUntilExit()

if task.terminationStatus != 0 {
    print("ERROR: iconutil failed with status \(task.terminationStatus)")
    exit(1)
}

// Clean up iconset directory
try fm.removeItem(atPath: iconsetPath)

print("Done! AppIcon.icns written to \(outputPath)")
