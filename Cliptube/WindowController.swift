//
//  WindowController.swift
//  Cliptube
//
//  Created by Daniel Vollmer on 05.10.20.
//

import AppKit
import AVKit

class WindowController: NSWindowController
{

  @IBOutlet var playerView: AVPlayerView!
  var volumeKVOToken: NSKeyValueObservation?

  override var windowNibName: NSNib.Name? {
    return NSNib.Name("DocumentWindow")
  }

  // let our main area work as drag handle
  override func mouseDown(with mouseDownEvent: NSEvent) {
    let window = self.window!
    window.performDrag(with: mouseDownEvent)
  }


  override func windowDidLoad() {
    guard let window = self.window else { return }
    guard let document = document as? Document, let asset = document.asset else { return }

    if let naturalSize = asset.tracks(withMediaType: .video).first?.naturalSize {
      window.setContentSize(naturalSize)
      window.contentAspectRatio = naturalSize
    }

    let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
    player.automaticallyWaitsToMinimizeStalling = true
    player.volume = UserDefaults.standard.volume
    self.playerView.allowsPictureInPicturePlayback = true
    self.playerView.player = player
    // let's note volume changes, so we can update our default volume
    volumeKVOToken = player.observe(\.volume, options: [.old, .new]) { [] (player, change) in
      guard let oldValue = change.oldValue,
            let newValue = change.newValue
      else { return }
      if oldValue == newValue { return }
      if newValue != UserDefaults.standard.volume {
        UserDefaults.standard.volume = newValue
      }
    }
  }

  deinit {
    volumeKVOToken?.invalidate()
    playerView?.player?.pause()
  }

}
