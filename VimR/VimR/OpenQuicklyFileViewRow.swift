/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class OpenQuicklyFileViewRow: NSTableRowView {

  override func drawSelection(in dirtyRect: NSRect) {
    if self.isSelected {
      NSColor.selectedControlColor.set()
    } else {
      NSColor.clear.set()
    }

    self.rectsBeingDrawn().forEach { NSIntersectionRect($0, dirtyRect).fill(using: .sourceOver) }
  }

  private func rectsBeingDrawn() -> [CGRect] {
    var rectsPtr: UnsafePointer<CGRect>? = nil
    var count: Int = 0
    self.getRectsBeingDrawn(&rectsPtr, count: &count)

    return Array(UnsafeBufferPointer(start: rectsPtr, count: count))
  }
}
