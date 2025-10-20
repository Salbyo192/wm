#!/bin/bash
# macOS Tiling Window Manager in a single Bash script

TMPFILE=$(mktemp /tmp/twm.XXXXXX.swift)

cat > "$TMPFILE" << 'EOF'
import Cocoa
import Quartz

// Simple Tiling Window Manager
class TilingWM {
    let screen = NSScreen.main!
    
    func tileWindows() {
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        let windowListInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as NSArray? as? [[String: Any]] ?? []
        
        var visibleWindows: [[String: Any]] = []
        
        for window in windowListInfo {
            if let layer = window[kCGWindowLayer as String] as? Int, layer == 0 {
                visibleWindows.append(window)
            }
        }
        
        let count = visibleWindows.count
        guard count > 0 else { return }
        
        let screenFrame = screen.visibleFrame
        let width = screenFrame.width / CGFloat(count)
        let height = screenFrame.height
        
        for (i, window) in visibleWindows.enumerated() {
            if let pid = window[kCGWindowOwnerPID as String] as? pid_t {
                
                let x = screenFrame.origin.x + CGFloat(i) * width
                let y = screenFrame.origin.y
                
                let axApp = AXUIElementCreateApplication(pid)
                var axWindows: CFTypeRef?
                AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &axWindows)
                
                if let axWindows = axWindows as? [AXUIElement], let axWindow = axWindows.first {
                    var position = CGPoint(x: x, y: y)
                    var size = CGSize(width: width, height: height)
                    
                    if let posValue = AXValueCreate(.cgPoint, &position) {
                        AXUIElementSetAttributeValue(axWindow, kAXPositionAttribute as CFString, posValue)
                    }
                    
                    if let sizeValue = AXValueCreate(.cgSize, &size) {
                        AXUIElementSetAttributeValue(axWindow, kAXSizeAttribute as CFString, sizeValue)
                    }
                }
            }
        }
    }
}

let wm = TilingWM()

// Run tiling periodically
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    wm.tileWindows()
}

RunLoop.main.run()
EOF

# Run the Swift script
swift "$TMPFILE" && rm "$TMPFILE"

