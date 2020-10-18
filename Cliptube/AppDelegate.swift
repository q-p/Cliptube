//
//  AppDelegate.swift
//  Cliptube
//
//  Created by Daniel Vollmer on 03.10.20.
//

import AppKit
import XCDYouTubeKit
import Combine


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

  @IBOutlet var watchClipboardMenuItem : NSMenuItem!

  let dc: DocumentController
  var pbWatcher: AnyCancellable? // our pasteboard watcher
  var historySizeKVOToken: NSKeyValueObservation?


  override init() {
    UserDefaults.standard.registerMyDefaults()
    dc = DocumentController()
  }


  func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { return false; }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    updateWatcher(shouldWatch: UserDefaults.standard.shouldWatchClipboard)
    historySizeKVOToken = UserDefaults.standard.observe(\.historySize, options: [.old, .new]) { [weak self] (defaults, change) in
      guard let self = self,
            let oldValue = change.oldValue,
            let newValue = change.newValue
      else { return }
      if oldValue == newValue { return }
      let oldHistoryCount = self.dc.history.count
      self.dc.history.maxSize = newValue
      if newValue < oldHistoryCount {
        // update stored history (because setting the new maxSize has truncated it)
        UserDefaults.standard.history = self.dc.history.items
      }
    }
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    pbWatcher = nil
    historySizeKVOToken?.invalidate()
    UserDefaults.standard.history = dc.history.items
  }


  /// Enables or disables clipboard watching depending on the argument, and sets the menu item appropriately.
  func updateWatcher(shouldWatch: Bool) {
    if shouldWatch {
      watchClipboardMenuItem.state = .on
      if pbWatcher == nil {
        pbWatcher = PasteboardPublisher().sink { maybeURLs in
          self.dc.openAllVideos(maybeURLs: maybeURLs, display: true)
        }
      }
    } else {
      watchClipboardMenuItem.state = .off
      pbWatcher = nil
    }
  }

  @IBAction func toggleWatchClipBoard(sender: NSMenuItem) {
    let shouldWatchClipboard = sender.state == .off // we invert the current state to obtain the desired state
    UserDefaults.standard.shouldWatchClipboard = shouldWatchClipboard
    updateWatcher(shouldWatch: shouldWatchClipboard)
  }


  func menuNeedsUpdate(_ menu: NSMenu) {
    if menu.title == "History" {
      menu.removeAllItems()
      let historyItems = dc.history.items
      for (id, title) in historyItems {
        let item = NSMenuItem(title: title, action: #selector(DocumentController.openHistoryItem), keyEquivalent: "")
        item.representedObject = id
        menu.addItem(item)
      }
      if historyItems.count > 0 {
        menu.addItem(NSMenuItem.separator())
      }
      menu.addItem(NSMenuItem(title: "Clear History", action: #selector(DocumentController.clearHistory), keyEquivalent: ""))
    }
  }

  @IBAction func showHelp(_ sender: Any?) {
    NSWorkspace.shared.open(URL(string: "https://www.github.com/q-p/Cliptube")!)
  }

}


extension UserDefaults {
  /// The key associated with the Watch Clipboard.
  static let WatchClipboardKey = "watchClipboard"
  /// Synthesized variable for shouldWatchClipboard, backed by the UserDefaults instance.
  var shouldWatchClipboard: Bool {
    get { return self.bool(forKey: UserDefaults.WatchClipboardKey) }
    set { self.set(newValue, forKey: UserDefaults.WatchClipboardKey) }
  }

  /// The key associated with the Volume.
  static let VolumeKey = "volume"
  /// Synthesized variable for Volume, backed by the UserDefaults instance.
  var volume: Float {
    get { return self.float(forKey: UserDefaults.VolumeKey) }
    set { self.set(newValue, forKey: UserDefaults.VolumeKey) }
  }

  /// The key associated with the HistorySize.
  static let HistorySizeKey = "historySize"
  /// Synthesized variable for HistorySize, backed by the UserDefaults instance.
  @objc dynamic var historySize: Int {
    get { return self.integer(forKey: UserDefaults.HistorySizeKey) }
    set { self.set(newValue, forKey: UserDefaults.HistorySizeKey) }
  }

  static let HistoryKey = "history"
  static let HistoryIDKey = "id"
  static let HistoryTitleKey = "title"
  /// Synthesized variable for History, backed by the UserDefaults instance.
  var history: [(String, String)] {
    get {
      guard let array = self.array(forKey: UserDefaults.HistoryKey) else { return [] }
      let available = min(array.count, self.historySize)
      var result: [(String, String)] = []
      result.reserveCapacity(available)
      for itemAny in array.prefix(available) {
        guard let dict = itemAny as? Dictionary<String, String>,
              let id = dict[UserDefaults.HistoryIDKey],
              let title = dict[UserDefaults.HistoryTitleKey]
        else { continue }
        result.append((id, title))
      }
      return result
    }
    set {
      let available = min(newValue.count, self.historySize)
      self.set(newValue.prefix(available).map { [UserDefaults.HistoryIDKey: $0, UserDefaults.HistoryTitleKey: $1] },
        forKey: UserDefaults.HistoryKey)
    }
  }


  /// Registers the defaults for Cliptube.
  func registerMyDefaults() {
    self.register(defaults: [
      UserDefaults.WatchClipboardKey: true,
      UserDefaults.HistorySizeKey: 20,
      UserDefaults.HistoryKey: [],
      UserDefaults.VolumeKey: 0.5,
//      "NSQuitAlwaysKeepsWindows": true,
    ])
  }
}
