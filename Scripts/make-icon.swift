import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fatalError("Usage: swift Scripts/make-icon.swift OUTPUT.icns")
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let fileManager = FileManager.default
let iconsetURL = fileManager.temporaryDirectory
    .appendingPathComponent("FileTimeEdit-\(UUID().uuidString).iconset")
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
defer { try? fileManager.removeItem(at: iconsetURL) }

let representations: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for representation in representations {
    let size = NSSize(width: representation.pixels, height: representation.pixels)
    let image = NSImage(size: size)
    image.lockFocus()

    let inset = CGFloat(representation.pixels) * 0.06
    let radius = CGFloat(representation.pixels) * 0.2
    let background = NSBezierPath(
        roundedRect: NSRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset),
        xRadius: radius,
        yRadius: radius
    )
    NSColor(calibratedRed: 0.12, green: 0.44, blue: 0.95, alpha: 1).setFill()
    background.fill()

    let configuration = NSImage.SymbolConfiguration(
        pointSize: CGFloat(representation.pixels) * 0.5,
        weight: .medium
    )
    if let symbol = NSImage(
        systemSymbolName: "calendar.badge.clock",
        accessibilityDescription: nil
    )?.withSymbolConfiguration(configuration) {
        let symbolSize = symbol.size
        let origin = NSPoint(
            x: (size.width - symbolSize.width) / 2,
            y: (size.height - symbolSize.height) / 2
        )
        NSColor.white.set()
        symbol.draw(
            at: origin,
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
    }

    image.unlockFocus()
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Unable to render app icon")
    }
    try png.write(to: iconsetURL.appendingPathComponent(representation.name))
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["--convert", "icns", iconsetURL.path, "--output", outputURL.path]
try iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else {
    fatalError("iconutil failed with status \(iconutil.terminationStatus)")
}