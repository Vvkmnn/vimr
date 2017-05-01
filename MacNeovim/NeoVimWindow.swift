/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import SwiftNeoVim
import PureLayout

protocol NeoVimWindowDelegate: class {

  func neoVimWindowDidClose(neoVimWindow: NeoVimWindow)
}

class NeoVimWindow: NSObject, NSWindowDelegate, NeoVimViewDelegate {

  var window: NSWindow {
    return self.windowController.window!
  }

  var view: NSView {
    return self.windowController.window!.contentView!
  }

  weak var delegate: NeoVimWindowDelegate?

  init(delegate: NeoVimWindowDelegate) {
    self.delegate = delegate
    self.windowController = NSWindowController(windowNibName: "NeoVimWindow")
    self.neoVimView = NeoVimView(frame: .zero, config: NeoVimView.Config(useInteractiveZsh: false))

    super.init()
    self.addViews()

    self.window.delegate = self
    self.window.makeFirstResponder(self.neoVimView)
  }

  func closeNeoVimWithoutSaving() {
    self.neoVimView.closeAllWindowsWithoutSaving()
  }

  fileprivate let windowController: NSWindowController
  fileprivate let neoVimView: NeoVimView
  fileprivate var defaultFont: NSFont = NeoVimView.defaultFont

  fileprivate let fontManager = NSFontManager.shared()

  fileprivate func addViews() {
    self.neoVimView.configureForAutoLayout()
    self.view.addSubview(self.neoVimView)
    self.neoVimView.autoPinEdgesToSuperviewEdges()

    self.neoVimView.delegate = self
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - IBActions
extension NeoVimWindow {

  // FIXME: the following three actions should be implemented by NeoVimView...
  @IBAction func resetFontSize(_ sender: Any?) {
    self.neoVimView.font = self.defaultFont
  }

  @IBAction func makeFontBigger(_ sender: Any?) {
    let curFont = self.neoVimView.font
    let font = self.fontManager.convert(curFont, toSize: min(curFont.pointSize + 1, NeoVimView.maxFontSize))
    self.neoVimView.font = font
  }

  @IBAction func makeFontSmaller(_ sender: Any?) {
    let curFont = self.neoVimView.font
    let font = self.fontManager.convert(curFont, toSize: max(curFont.pointSize - 1, NeoVimView.minFontSize))
    self.neoVimView.font = font
  }
}

// MARK: - NSWindowDelegate
extension NeoVimWindow {

  func windowShouldClose(_: Any) -> Bool {
    guard self.neoVimView.isCurrentBufferDirty() else {
      self.neoVimView.closeCurrentTab()
      return false
    }

    let alert = NSAlert()
    alert.addButton(withTitle: "Cancel")
    alert.addButton(withTitle: "Discard and Close")
    alert.messageText = "The current buffer has unsaved changes!"
    alert.alertStyle = .warning
    alert.beginSheetModal(for: self.window, completionHandler: { response in
      if response == NSAlertSecondButtonReturn {
        self.neoVimView.closeCurrentTabWithoutSaving()
      }
    })

    return false
  }
}

// MARK: - NeoVimViewDelegate
extension NeoVimWindow {

  func neoVimStopped() {
    self.delegate?.neoVimWindowDidClose(neoVimWindow: self)
    self.windowController.close()
  }

  func set(title: String) {
    self.window.title = title
  }

  func set(dirtyStatus: Bool) {
    self.window.isDocumentEdited = dirtyStatus
  }

  func cwdChanged() {
  }

  func bufferListChanged() {
  }

  func tabChanged() {
  }

  func currentBufferChanged(_ currentBuffer: NeoVimBuffer) {
    self.window.representedURL = currentBuffer.url
  }

  func ipcBecameInvalid(reason: String) {
    let alert = NSAlert()
    alert.addButton(withTitle: "Close")
    alert.messageText = "Sorry, an error occurred."
    alert.informativeText = "VimR encountered an error from which it cannot recover. This window will now close.\n"
                            + reason
    alert.alertStyle = .critical
    alert.beginSheetModal(for: self.window) { _ in
      self.neoVimStopped()
    }
  }

  func scroll() {
  }

  func cursor(to: Position) {
  }
}
