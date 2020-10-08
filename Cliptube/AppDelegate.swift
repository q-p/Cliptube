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
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet var watchClipboardMenuItem : NSMenuItem!

  let dc = DocumentController() // ensure the shared instance will be this one
  var pbWatcher: AnyCancellable? // our pasteboard watcher


  func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
    return false;
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let defaults = UserDefaults.standard
    defaults.registerMyDefaults()
    let shouldWatchClipboard = defaults.shouldWatchClipboard
    updateWatcher(shouldWatch: shouldWatchClipboard)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    pbWatcher = nil
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

}


extension UserDefaults {
  /// The key associated with the Watch Clipboard bool.
  static let WatchClipboardKey = "WatchClipboard"
  /// Synthesized variable for shouldWatchClipboard flag, backed by the UserDefaults instance.
  var shouldWatchClipboard: Bool {
    get { return self.bool(forKey: UserDefaults.WatchClipboardKey) }
    set { self.set(newValue, forKey: UserDefaults.WatchClipboardKey) }
  }
  /// Registers the defaults for Cliptube.
  func registerMyDefaults() {
    self.register(defaults: [
      UserDefaults.WatchClipboardKey: true,
    ])
  }
}
